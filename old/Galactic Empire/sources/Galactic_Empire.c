
#include "Galaxy.h"
#include <Sound.h>
#include <stdio.h>
#include <fp.h>



 
 

/* Button ID */
#define	I_Launch 	12
/* Button ID */
#define	I_Launch_All 	13
/* Button ID */
#define	I_Launch_One 	14
/* Button ID */
#define	I_Do_Battle 	15
/* Scrollbar ID */
#define	I_Scroll_bar 	11
#define	I_Constant_Feed 	16


static Rect	tempRect,temp2Rect;
static short	Index;
static ControlHandle	CtrlHandle;
static Str255	sTemp;
static OSErr	MyErr;
static ControlHandle	C_Launch;
static ControlHandle	C_Launch_All;
static ControlHandle	C_Launch_One;
static ControlHandle	C_Do_Battle;
static ControlHandle	C_Constant_Feed;
static ControlHandle	C_Scroll_bar;

Rect			gamerect = {0,0,435,515};

WindowPtr		gamewind = 0L;
PlanetRec		precs[PLANETROWS*PLANETCOLS] = {0};
short			feedtolist[PLANETROWS*PLANETCOLS] = {-1};
TransRec		trecs[MAXTRANSRECS] = {0};
short			tottrecs = 0;
short			totplanets = (PLANETROWS * PLANETCOLS);
extern			SHandle	saved_enemies;
short			elist[8] = {0};			/* Holds our enemy list */
short			dlist[8] = {0};			/* Dead enemy list 		*/
short			totenemies = 0;			/* Count of our enemies */
short			lineison = 0;
Point			startpt,lastpt;
short			fmplanet = 0;
short			toplanet = 0;
short			selected = 0;
short			curryear = 0;
short			currinput= 0;
short			currtime = 0;
short			shipstolaunch = 0;
short			closeflag = 0;
short			gamesaved = 0;
short			soundFlag = 1;	/* Default sound ON */
extern	short	wehavewon;
extern	short	wehavelost;
SndChannelPtr	savechan;

Rect			inforectall = 	{246,537,425,621};

Rect			timerect	=	{27,525,46,617};
Rect			yearrect	=	{72,525,91,617};

Rect			finforect = 	{250,538,262,620};
Rect			ficonrect = 	{263,560,295,592};
Rect			fshiprect = 	{296,538,308,620};
Rect			findurect = 	{309,538,321,620};

Rect			statrect  = 	{322,538,351,620};
Rect			launchrect=		{328,538,344,620};

Rect			tinforect = 	{352,538,364,620};
Rect			ticonrect = 	{365,560,397,592};
Rect			tshiprect = 	{398,538,410,620};
Rect			tindurect = 	{411,538,423,620};

PixPatHandle	gameAreaPat = 0L;
PixPatHandle	infoAreaPat = 0L;
PixPatHandle	linePat = 0L;

CIconHandle		planetIcons[12];

PicHandle		planetPics[12];

void  
Init_Galactic_Empire()
{
	short	i;
	// Init all icon handles we use
	
	for(i=0;i<10;i++)
		{
		planetIcons[i] = GetCIcon(i+ICONOFF);
		}
	// Init all planet pictures we use
	for(i=0;i<12;i++)
		{
		planetPics[i] = GetPicture(i);
		}
	// Init the background drawing patterns we use
	
	gameAreaPat =GetPixPat(128);
	infoAreaPat =GetPixPat(129);
	linePat		=GetPixPat(130);

	gamewind = 0L;
}

short 
Close_Galactic_Empire(WindowPtr  whichWindow,TEHandle */*theInput*/)
{
	 
	if ((gamewind != 0L) && ((gamewind == whichWindow) || (whichWindow == (WindowPtr)-1)))
	{
		if(!closeflag && !gamesaved)			/* If not the end of the game.... */
		{
		/* Ask if we should save the game here */
			if(Check_Saved())return(1);
		}
		DisposeWindow(gamewind);
		Clear_Dead_Aliens(); 
		gamewind = 0L;
		lineison = 0;
		totenemies = 0; 
	}
	return(0); 
}

void
Show_Visit()
{
	short	i,j;
	Str255	infostr,tmp;

	EraseRect(&statrect);
	if((precs[fmplanet].owns != HUMAN) && (!precs[fmplanet].homeplanet))
	{
		if(precs[fmplanet].lastvisit)
   		{
	   		i = precs[fmplanet].lastvisit/10;
	   		j = precs[fmplanet].lastvisit % 10;
	   		pStrCopy("\pLast Visited ",infostr);
	   		NumToString((long)i,tmp);
	   		pStrCat(tmp,infostr);
	   		pStrCat("\p.",infostr);
	   		NumToString((long)j,tmp);
	   		pStrCat(tmp,infostr);
   		}
   		else
   		{
   			pStrCopy("\pNever Visited",infostr);
   		}
		TextFont(geneva);
		TextSize(9);	
		TextBox(&infostr[1], infostr[0], &statrect, teJustCenter);
		TextFont(0);
		TextSize(12);
	}
} 

void
Show_From_Data()
{
	short	showships,showindustry;
	Str255	infostr;

	showships = showindustry = 0;

	if((precs[fmplanet].owns == HUMAN) || 
	   (precs[fmplanet].homeplanet) ||
	   ((precs[fmplanet].lastvisit && (curryear - precs[fmplanet].lastvisit) < 11)) || //why 11
	   (GETOWNED(precs[fmplanet],HUMAN)) ||
	   (precs[fmplanet].humanpings >= 3)) showships = 1;
   
	if((precs[fmplanet].owns == HUMAN) || 
	   (precs[fmplanet].homeplanet) ||
	   (GETOWNED(precs[fmplanet],HUMAN)) ||
	   (precs[fmplanet].humanpings >= 3)) showindustry = 1;

	EraseRect(&finforect);
	EraseRect(&fshiprect);
	EraseRect(&findurect);

	switch(precs[fmplanet].owns)
	{
		case INDEPENDENT:	{pStrCopy("\pIndep. World",infostr);break;}
		case HUMAN:			{pStrCopy("\pHuman World",infostr);break;}
		case GUBRU:			{pStrCopy("\pGubru World",infostr);break;}
		case CZIN:			{pStrCopy("\pCzin World",infostr);break;}
		case BLOBS:			{pStrCopy("\pBlob World",infostr);break;}
		case BOTS:			{pStrCopy("\pBot World",infostr);break;}
		case ARACHS:		{pStrCopy("\pArachs World",infostr);break;}
		case MUTANTS:		{pStrCopy("\pMutant World",infostr);break;}
		case NUKES:			{pStrCopy("\pNuke World",infostr);break;}
		case BOZOS:			{pStrCopy("\pBozo World",infostr);break;}
	}

	TextFont(geneva);
	TextSize(9);	
	TextBox(&infostr[1], infostr[0], &finforect, teJustCenter);

	EraseRect(&ficonrect);
	PlotCIcon(&ficonrect,planetIcons[precs[fmplanet].owns]);

	if(showships)
	{
		NumToString((long)precs[fmplanet].ships,infostr);
		pStrCat("\p Ships",infostr);
	}
	else
	{
		pStrCopy("\p ? Ships",infostr);
	}
	TextBox(&infostr[1], infostr[0], &fshiprect, teJustCenter);

	if(showindustry)
	{
		NumToString((long)precs[fmplanet].industry,infostr);
		pStrCat("\p Industry",infostr);
	}
	else
	{
		pStrCopy("\p ? Industry",infostr);
	}
	TextBox(&infostr[1], infostr[0], &findurect, teJustCenter);

	TextFont(0);   
	TextSize(12);
  
}

void
Show_To_Data()
{
	short	showships,showindustry;
	Str255	infostr;

	showships = showindustry = 0;

	if((precs[toplanet].owns == HUMAN) || 
	   (precs[toplanet].homeplanet) ||
	   ((precs[toplanet].lastvisit && (curryear - precs[toplanet].lastvisit) < 11)) ||
	   (GETOWNED(precs[toplanet],HUMAN)) ||
	   (precs[toplanet].humanpings >= 3)) showships = 1;
   
	if((precs[toplanet].owns == HUMAN) || 
	   (precs[toplanet].homeplanet) ||
	   (GETOWNED(precs[toplanet],HUMAN)) ||
	   (precs[toplanet].humanpings >= 3)) showindustry = 1;

	EraseRect(&tinforect);
	EraseRect(&tshiprect);
	EraseRect(&tindurect);

	switch(precs[toplanet].owns)
	{
		case INDEPENDENT:	{pStrCopy("\pIndep. World",infostr);break;}
		case HUMAN:			{pStrCopy("\pHuman World",infostr);break;}
		case GUBRU:			{pStrCopy("\pGubru World",infostr);break;}
		case CZIN:			{pStrCopy("\pCzin World",infostr);break;}
		case BLOBS:			{pStrCopy("\pBlob World",infostr);break;}
		case BOTS:			{pStrCopy("\pBot World",infostr);break;}
		case ARACHS:		{pStrCopy("\pArachs World",infostr);break;}
		case MUTANTS:		{pStrCopy("\pMutant World",infostr);break;}
		case NUKES:			{pStrCopy("\pNuke World",infostr);break;}
		case BOZOS:			{pStrCopy("\pBozo World",infostr);break;}
	}

	TextFont(geneva);
	TextSize(9);	
	TextBox(&infostr[1], infostr[0], &tinforect, teJustCenter);

	PlotCIcon(&ticonrect,planetIcons[precs[toplanet].owns]);

	if(showships)
	{
		NumToString((long)precs[toplanet].ships,infostr);
		pStrCat("\p Ships",infostr);
	}
	else
	{
		pStrCopy("\p ? Ships",infostr);
	}
	TextBox(&infostr[1], infostr[0], &tshiprect, teJustCenter);

	if(showindustry)
	{
		NumToString((long)precs[toplanet].industry,infostr);
		pStrCat("\p Industry",infostr);
	}
	else
	{
		pStrCopy("\p ? Industry",infostr);
	}
	TextBox(&infostr[1], infostr[0], &tindurect, teJustCenter);

	TextFont(0);   
	TextSize(12);
  
}
 
/* Update our window, someone uncovered a part of us */
void  
UpDate_Galactic_Empire(WindowPtr  whichWindow)
{
	WindowPtr   SavePort;
	/*Str255   	sTemp;*/
	short		i;
	Rect		r;
	
	if ((gamewind != 0L)  &&  (gamewind == whichWindow))
		{		
		GetPort(&SavePort);
		SetPort(gamewind);
		r = (*gamewind).portRect;
		EraseRect(&r);
		r.left = gamerect.right;
		InsetRect(&r,1,1);
		FillCRect(&r,infoAreaPat);
		FillCRect(&gamerect,gameAreaPat);
		/* Draw the planets	*/
		
		for(i=0;i<totplanets;i++)
			{
			if(precs[i].owns == NOPLANET)continue;
			r.top = (precs[i].row * PLANETLENGTH) + 1;
			r.left = (precs[i].col * PLANETWIDTH) + 1;
			r.right = r.left + PLANETWIDTH;
			r.bottom = r.top + PLANETLENGTH;
			if((precs[i].owns == HUMAN) && (precs[i].industry == 0))
				{
				DrawPicture ( planetPics[HUMAN0] , &r );
				}
			else
				{
				if((precs[i].owns == HUMAN) && (feedtolist[i] != (-1)))
					{
					DrawPicture ( planetPics[HUMANFEED] , &r );
					}
				else
					{
					DrawPicture ( planetPics[precs[i].owns] , &r );
					}
				}
			if(selected && (i == fmplanet))
				{
				InsetRect(&r,1,1);
				FrameRect(&r);
				Show_From_Data();
				}
			}
		EraseRect(&inforectall);
		FrameRect(&inforectall);
		PenSize(2,2);
		MoveTo(inforectall.left+2,inforectall.bottom);
		LineTo(inforectall.right,inforectall.bottom);
		MoveTo(inforectall.right,inforectall.top+2);
		LineTo(inforectall.right,inforectall.bottom);
		PenSize(1,1);

		/* Draw a rectangle, Time Rect  */
		EraseRect(&timerect);
		FrameRect(&timerect);
		PenPixPat(gameAreaPat);
		MoveTo(timerect.left+1,timerect.bottom-1);
		LineTo(timerect.right-1,timerect.bottom-1);
		MoveTo(timerect.right-1,timerect.top+1);
		LineTo(timerect.right-1,timerect.bottom-1);
		PenNormal();
		PenSize(1,1);
		
		/* Draw a rectangle, Year Rect  */
		EraseRect(&yearrect);
		FrameRect(&yearrect);
		PenPixPat(gameAreaPat);
		MoveTo(yearrect.left+1,yearrect.bottom-1);
		LineTo(yearrect.right-1,yearrect.bottom-1);
		MoveTo(yearrect.right-1,yearrect.top+1);
		LineTo(yearrect.right-1,yearrect.bottom-1);
		PenNormal();
		PenSize(1,1);


		TextFont(systemFont);
		/* Draw a string of text,   */
		PenNormal();
		SetRect(&tempRect, 525,8,617,23);
		MoveTo(tempRect.left+7,tempRect.bottom-3);
		TextMode(srcBic);
		DrawString("\pTravel Time");
		MoveTo(tempRect.left+6,tempRect.bottom-4);
		TextMode(srcOr);
		DrawString("\pTravel Time");
		PenNormal();
		TextFont(applFont);

		TextFont(systemFont);
		/* Draw a string of text,   */
		PenNormal();
		SetRect(&tempRect, 549,53,591,68);
		MoveTo(tempRect.left+7,tempRect.bottom-3);
		TextMode(srcBic);
		DrawString("\pYear");
		MoveTo(tempRect.left+6,tempRect.bottom-4);
		TextMode(srcOr);
		DrawString("\pYear");
		PenNormal();
		TextFont(applFont);
		
		Show_Year();
				
		FrameRect(&gamerect);
		if(lineison)
			{
			PenPixPat(linePat);
			PenMode(patXor);
			MoveTo(startpt.h,startpt.v);
			LineTo(lastpt.h,lastpt.v);
			PenNormal();
			PenMode(patCopy);
			Show_To_Data();
			}
		else
			{
			Show_Input();
			}
		DrawControls(gamewind);
		SetPort(SavePort);
		}

}

void
Show_Year()
{
short	i,j;

Str255	infostr,tmp;

InsetRect(&yearrect,2,2);
EraseRect(&yearrect);
TextFont(0);
i = curryear/10;
j = curryear % 10;

NumToString((long)i,infostr);
pStrCat("\p.",infostr);
NumToString((long)j,tmp);
pStrCat(tmp,infostr);
TextBox(&infostr[1], infostr[0], &yearrect, teJustCenter);
InsetRect(&yearrect,-2,-2);
}

void
Show_Input()
{
Str255	infostr;

EraseRect(&statrect);
TextFont(geneva);
TextSize(9);
switch(currinput)
	{
	case HUMAN:		{pStrCopy("\pHuman Input",infostr);break;}
	case GUBRU:		{pStrCopy("\pGubru Input",infostr);break;}
	case CZIN:		{pStrCopy("\pCzin Input",infostr);break;}
	case BLOBS:		{pStrCopy("\pBlob Input",infostr);break;}
	case BOTS:		{pStrCopy("\pBot Input",infostr);break;}
	case ARACHS:	{pStrCopy("\pArach Input",infostr);break;}
	case MUTANTS:	{pStrCopy("\pMutant Input",infostr);break;}
	case NUKES:		{pStrCopy("\pNuke Input",infostr);break;}
	case BOZOS:		{pStrCopy("\pBozo Input",infostr);break;}
	default:		{pStrCopy("\pBattle Phase",infostr);break;}
	}

TextBox(&infostr[1], infostr[0], &statrect, teJustCenter);
TextFont(0);
TextSize(12);
}

void
Calc_Time()
{
	double	distance,time;
	short	rowcnt,colcnt;

	rowcnt = (precs[fmplanet].row - precs[toplanet].row);
	if(rowcnt < 0) rowcnt *= (-1);
	rowcnt *= rowcnt;
	colcnt = (precs[fmplanet].col - precs[toplanet].col);
	if(colcnt < 0) colcnt *= (-1);
	colcnt *= colcnt;

	distance = sqrt((double)(rowcnt + colcnt));
	time = distance * 0.35;

	currtime = (short)(time * 10.0);
}

void
Show_Dist_Time()
{
	double	distance,time;
	short	rowcnt,colcnt;
	Str255	infostr;

	rowcnt = (precs[fmplanet].row - precs[toplanet].row);
	if(rowcnt < 0)rowcnt *= (-1);
	rowcnt *= rowcnt;
	colcnt = (precs[fmplanet].col - precs[toplanet].col);
	if(colcnt < 0)colcnt *= (-1);
	colcnt *= colcnt;

	distance = sqrt((double)(rowcnt + colcnt));
	time = distance * 0.35;

	TextFont(0);


	InsetRect(&timerect,1,1);
	EraseRect(&timerect);
	sprintf((char *)&infostr[0],"%02.1f",time);
	CtoPstr((char *)&infostr[0]);
	TextBox(&infostr[1], infostr[0], &timerect, teJustCenter);
	InsetRect(&timerect,-1,-1);
	currtime = (short)(time * 10.0);
}
/*  ===========================================  */

void  
HandleWScrollBar (short code, short Start, short Stop, short Increment, short LIncrement, ControlHandle theControl,Point myPt)
{
	short   theValue;
	Str255	infostr;
	long	crap;
	
	do 
	{
		HiliteControl(theControl, code);	
		theValue = GetCtlValue(theControl);	
		
		if (code == inUpButton)
		{
			theValue = theValue - Increment;
			if (theValue < Start)
				theValue = Start;
		}
		
		if (code == inDownButton)
		{
			theValue = theValue + Increment;
			if (theValue > Stop)
				theValue = Stop;
		}
		
		if (code == inPageUp)
		{
			theValue = theValue - LIncrement;
			if (theValue < Start)
				theValue = Start;
		}
		
		if (code == inPageDown)
		{
			theValue = theValue + LIncrement;
			if (theValue > Stop)
				theValue = Stop;
		}
		
		if (code == inThumb)
		{
			code = TrackControl(theControl, myPt,(ControlActionUPP)(-1L));
			theValue = GetCtlValue(theControl);
		}
		
		SetCtlValue(theControl, theValue);
		
		theValue *= (-1);
		NumToString((long)theValue,infostr);
		pStrCat("\p Ships",infostr);
		TextBox(&infostr[1], infostr[0], &launchrect, teJustCenter);
		
		if(theValue > 0)
		{
			HiliteControl(C_Launch_All,255);
			HiliteControl(C_Launch_One,255);
			HiliteControl(C_Constant_Feed,255);
			HiliteControl(C_Launch,0);
		}
		else
		{
			HiliteControl(C_Launch_All,0);
			HiliteControl(C_Launch_One,0);
			HiliteControl(C_Constant_Feed,0);
			HiliteControl(C_Launch,255);
		}
		while(((code == inPageUp) || (code == inPageDown)) && StillDown())
		{
		}	/* Just for grey area */
		HiliteControl(theControl, 0);
		Delay(6L,&crap);
	}
	while (StillDown( ) == TRUE);
	
	if(theValue > 0)
	{
		HiliteControl(C_Launch,0);
		shipstolaunch = theValue;
	}
	else
	{
		HiliteControl(C_Launch,255);
	}
}

void 
Do_A_ScrollBar(short code,ControlHandle theControl,Point myPt)
{
	short RefCon;
	short grayinc;

	if(precs[fmplanet].ships <= 10)grayinc = 1;
	if(precs[fmplanet].ships > 10)grayinc = 10;
	if(precs[fmplanet].ships >= 200)grayinc = 20;
	if(precs[fmplanet].ships >= 300)grayinc = 30;
	if(precs[fmplanet].ships >= 400)grayinc = 40;
	if(precs[fmplanet].ships >= 500)grayinc = 50;
	if(precs[fmplanet].ships >= 1000)grayinc = 100;
	if(precs[fmplanet].ships >= 2000)grayinc = 200;
	if(precs[fmplanet].ships >= 3000)grayinc = 300;
	if(precs[fmplanet].ships >= 4000)grayinc = 400;
	if(precs[fmplanet].ships >= 5000)grayinc = 500;

	RefCon = GetCRefCon(theControl);
	
	switch  (RefCon) 
	{
		case I_Scroll_bar:
			HandleWScrollBar(code,-(precs[fmplanet].ships),0,1,grayinc,theControl,myPt);
			break;
	
		default:
			break;
	}
}

/* ================================= */

void
Set_Home_Planet(short minrow,short mincol,short maxrow,short maxcol,short ptype)
{
	short	found,row,col,planet;
	double_t	n;

	found = 0;

	n = TickCount();			/* Seed the random number generator */

	while(!found)
	{
		n = randomx(&n);
		row = (short)((long)n % (long)maxrow);
		if((row < minrow) || (row > maxrow))continue;
		n = randomx(&n);
		col = (short)((long)n % (long)maxcol);
		if((col < mincol) || (col > maxcol))continue;
		planet = (row* PLANETCOLS) + col;
		if(precs[planet].owns == NOPLANET)
		{
			precs[planet].owns = ptype;
			precs[planet].row = row;
			precs[planet].col = col;
			precs[planet].industry = 10;
			precs[planet].ships = 100;
			precs[planet].lastvisit = 0;
			precs[planet].humanpings = 0;
			precs[planet].homeplanet = 1;
			SETOWNED(precs[planet],ptype);
			if(ptype == HUMAN)
			{
				precs[planet].humanpings= 3;
				selected = 1;
				fmplanet = planet;
			}
			found=1;
		}
	}	
}

void
Disable_Scroll()
{
	HiliteControl(C_Launch,255);
	HiliteControl(C_Launch_All,255);
	HiliteControl(C_Constant_Feed,255);
	HiliteControl(C_Launch_One,255);
	HiliteControl(CtrlHandle,255);
	InsetRect(&timerect,1,1);
	EraseRect(&timerect);
	InsetRect(&timerect,-1,-1);
}

void
Set_Up_Scroll()
{
	if(precs[fmplanet].ships)
	{
		HiliteControl(C_Launch_All,0);
		HiliteControl(C_Launch_One,0);
		HiliteControl(C_Constant_Feed,0);
		HiliteControl(CtrlHandle,0);
		SetCtlMin(CtrlHandle,-(precs[fmplanet].ships));
		SetCtlMax(CtrlHandle,0);
		SetCtlValue(CtrlHandle,0);
	}
	else
	{
		HiliteControl(C_Constant_Feed,0);
	}
	shipstolaunch = 0;
	Show_Dist_Time();
}

 
/* Open our window and draw everything */
void 
Open_Galactic_Empire(TEHandle	*/*theInput*/,short newgame)
{
	short	pcnt,planet,row,col,i;
	double_t	n;

	if (gamewind == 0L) 
	{
		gamewind = GetNewCWindow(1,0L, (WindowPtr)-1);
		SetPort(gamewind);
		
		/* Make a button, Launch  */
		C_Launch = GetNewControl(I_Launch,gamewind);
		
		/* Make a button, Launch All  */
		C_Launch_All = GetNewControl(I_Launch_All,gamewind);
		
		/* Make a button, Launch One  */
		C_Launch_One = GetNewControl(I_Launch_One,gamewind);
		
		/* Make a button, Do Battle  */
		C_Do_Battle = GetNewControl(I_Do_Battle,gamewind);

		C_Constant_Feed = GetNewControl(I_Constant_Feed,gamewind);
			
		/*  Make a scroll bar, Scroll bar   */
		CtrlHandle = GetNewControl(I_Scroll_bar,gamewind);

		wehavewon = wehavelost = 0;
		
		Disable_Scroll();

		if(newgame)
		{
			for(i=0;i<MAXTRANSRECS;i++)
			{
				trecs[i].fromrow = 0;
				trecs[i].fromcol = 0;
				trecs[i].fromowns = 0;
				trecs[i].torow = 0;
				trecs[i].tocol = 0;
				trecs[i].ships = 0;
				trecs[i].timeleft = 0;
			}
			tottrecs = 0;		
			for(i=0;i<PLANETROWS*PLANETCOLS;i++)
			{
				precs[i].owns = NOPLANET;
				precs[i].lastvisit = 0;
				precs[i].homeplanet = 0;
				precs[i].everowned = 0;
				precs[i].humanpings = 0;
				feedtolist[i] = (-1);
			}
			pcnt=0;
			n = TickCount();
				
			while(pcnt < 100)
			{
				n = randomx(&n);
				row = (short)((long)n % (long)PLANETROWS);
				n = randomx(&n);
				col = (short)((long)n % (long)PLANETCOLS);
				planet = (row* PLANETCOLS) + col;
				if(precs[planet].owns == NOPLANET)
				{
					SETOWNED(precs[planet],INDEPENDENT);
					precs[planet].owns = INDEPENDENT;
					precs[planet].row = row;
					precs[planet].col = col;
					n = randomx(&n);
					precs[planet].industry = (short)((long)n % 8L);
					precs[planet].ships = precs[planet].industry;
					pcnt++;
				}
			}

				
			/* Count our enemies */
			
			totenemies = 0;
			for(i=0;i<8;i++)dlist[i]=0;	/* Enemies not dead */
			if((**saved_enemies).dogubrus){elist[totenemies] = GUBRU;totenemies++;}		
			if((**saved_enemies).doczins){elist[totenemies] = CZIN;totenemies++;}			
			if((**saved_enemies).doblobs){elist[totenemies] = BLOBS;totenemies++;}			
			if((**saved_enemies).dobots){elist[totenemies] = BOTS;totenemies++;}			
			if((**saved_enemies).doarachs){elist[totenemies] = ARACHS;totenemies++;}			
			if((**saved_enemies).domutants){elist[totenemies] = MUTANTS;totenemies++;}			
			if((**saved_enemies).donukes){elist[totenemies] = NUKES;totenemies++;}			
			if((**saved_enemies).dobozos){elist[totenemies] = BOZOS;totenemies++;}	

			/* Select enemy and human home planets */
			
			switch(totenemies)
			{
				case 1:
					/* Put alien in upper left, us in lower right */
					/* Min row,Min col, Max row,Max col,Home type */
					Set_Home_Planet(0,0,11,10,elist[0]);
					Set_Home_Planet(18,20,27,32,HUMAN);
					break;
				case 2:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
				case 3:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(18,0,27,10,elist[2]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
				case 4:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(18,0,27,10,elist[2]);
					Set_Home_Planet(0,20,9,32,elist[3]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
				case 5:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(18,0,27,10,elist[2]);
					Set_Home_Planet(0,20,9,32,elist[3]);
					Set_Home_Planet(10,0,17,10,elist[4]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
				case 6:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(18,0,27,10,elist[2]);
					Set_Home_Planet(0,20,9,32,elist[3]);
					Set_Home_Planet(10,0,17,10,elist[4]);
					Set_Home_Planet(0,11,9,19,elist[5]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
				case 7:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(18,0,27,10,elist[2]);
					Set_Home_Planet(0,20,9,32,elist[3]);
					Set_Home_Planet(10,0,17,10,elist[4]);
					Set_Home_Planet(0,11,9,19,elist[5]);
					Set_Home_Planet(10,20,18,32,elist[6]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
				case 8:
					Set_Home_Planet(0,0,9,10,elist[0]);
					Set_Home_Planet(18,20,27,32,elist[1]);
					Set_Home_Planet(18,0,27,10,elist[2]);
					Set_Home_Planet(0,20,9,32,elist[3]);
					Set_Home_Planet(10,0,17,10,elist[4]);
					Set_Home_Planet(0,11,9,19,elist[5]);
					Set_Home_Planet(10,20,18,32,elist[6]);
					Set_Home_Planet(19,11,27,20,elist[7]);
					Set_Home_Planet(10,11,17,19,HUMAN);
					break;
			}
			
			/* Set the starting year to 0 */
			
			curryear = 0;
			gamesaved= 1;	/* For first turn only */
		}/* End if new game (instead of opened from file */
		
		currinput = HUMAN;
		closeflag = 0;
		
		ShowWindow(gamewind);
		SelectWindow(gamewind);
		
	}
	else
		SelectWindow(gamewind);
	
}

/* ================================= */

void
StartASound(short sndRsrcNum)
{
	OSErr			err;
	SndListHandle	thesnd;

	err = noErr;
	savechan = nil;
	if(soundFlag)
	{
		err =SndNewChannel(&savechan,sampledSynth,initStereo,nil);
		if(err == noErr)
		{
			thesnd = (SndListHandle)Get1Resource('snd ',sndRsrcNum);
			err = SndPlay(savechan, thesnd, TRUE);
		}
	}
}

void
EndASound()
{
	if(soundFlag && (savechan != nil))SndDisposeChannel(savechan,FALSE);
	savechan = nil;
} 

void  
Do_A_Button(ControlHandle	theControl)
{
	short	RefCon;

	HiliteControl(theControl, 10);
	RefCon = GetCRefCon(theControl);
	
	switch (RefCon)
	{
		case I_Launch:
			HiliteControl(theControl, 0);
			/* Play lunch ships sound */
			StartASound(kNormalLaunch);
			EndASound();
			Launch_Ships(shipstolaunch,false,false);
			break;
	
		case I_Launch_All:
			HiliteControl(theControl, 0);
			/* Play launch ships sound */
			StartASound(kNormalLaunch);
			EndASound();
			Launch_Ships(precs[fmplanet].ships,false,false);
			break;

		case I_Constant_Feed:
			HiliteControl(theControl, 0);
			/* Play constant feed sound */
			StartASound(kConstantFeed);
			EndASound();
			Launch_Ships(precs[fmplanet].ships,true,false);
			break;
	
		case I_Launch_One:
			HiliteControl(theControl, 0);
			/* Play launch one sound */
			StartASound(kLaunchOne);
			EndASound();
			Launch_Ships(1,false,false);
			break;
	
		case I_Do_Battle:
			De_Select();
			HiliteControl(theControl, 0);
			/* Play do battle sound */
			StartASound(kValkyries);
			EndASound();
			if(lineison)
				{
				PenPixPat(linePat);
				PenMode(patXor);
				MoveTo(startpt.h,startpt.v);
				LineTo(lastpt.h,lastpt.v);
				PenNormal();
				PenMode(patCopy);
				Disable_Scroll();
				lineison =0;
				}
			closeflag = Do_Battle();
			break;
	
		default:
			break;
	}
}

/* ================================= */
 
/* Handle action to our window, like controls */
void  
Do_Galactic_Empire(EventRecord	*myEvent, TEHandle	*/*theInput*/)
{
	short	code;
	short	row,col,planet;
	WindowPtr	whichWindow;
	Point	myPt;
	ControlHandle	theControl;
	Rect	r;
	Point		pt;

	/* Start of Window handler */
	if (gamewind != 0L)
	{
		code = FindWindow(myEvent->where, &whichWindow);
		
		if ((myEvent->what == mouseDown)  &&  (gamewind == whichWindow))
		{
			myPt = myEvent->where;
			GlobalToLocal(&myPt);
			 
			if (PtInRect(myPt,&gamerect) == TRUE)
			{
				if(selected)
				{
					if(lineison)
					{
						PenPixPat(linePat);
						PenMode(patXor);
						MoveTo(startpt.h,startpt.v);
						LineTo(lastpt.h,lastpt.v);
						PenNormal();
						PenMode(patCopy);
						Disable_Scroll();
						lineison =0;
					}
					r = inforectall;
					InsetRect(&r,1,1);
					EraseRect(&r);
					De_Select();
				}
				/* Calculate the planet rect of the point */
				
				row = myPt.v / PLANETLENGTH;
				if(row >= PLANETROWS)row = PLANETROWS-1;
				col = myPt.h / PLANETWIDTH;
				if(col >= PLANETCOLS)col = PLANETCOLS-1;
				planet = (row* PLANETCOLS) + col;
				
				if(precs[planet].owns != NOPLANET)
				{
					if(New_Select(planet,true))
					{
						Show_From_Data();
						Show_Visit();
						goto noloop;
					}
					Show_From_Data();
					Show_Visit();
				
					toplanet = fmplanet;
				
					/* Handle potential transport drawing */
					
					InsetRect(&r,-1,-1);
					myPt.h = (myPt.h & 0xFFF0) + 8;
					myPt.v = (myPt.v & 0xFFF0) + 8;
					lastpt = startpt = myPt;

					PenPixPat(linePat);
					PenMode(patXor);
					
					while(StillDown())
					{
						GetMouse(&pt);
						if(PtInRect(pt,&gamerect))
						{
							row = pt.v / PLANETLENGTH;
							if(row >= PLANETROWS)row = PLANETROWS-1;
							col = pt.h / PLANETWIDTH;
							if(col >= PLANETCOLS)col = PLANETCOLS-1;
							toplanet = (row* PLANETCOLS) + col;
							if(precs[toplanet].owns != NOPLANET)
							{
								pt.h = (pt.h & 0xFFF0) + 8;
								pt.v = (pt.v & 0xFFF0) + 8;
							}
							if(!EqualPt(lastpt,pt))
							{
								/* Erase old line */
								if(lineison)
								{
									MoveTo(startpt.h,startpt.v);
									LineTo(lastpt.h,lastpt.v);
									lineison = 0;
								}
								MoveTo(startpt.h,startpt.v);			/* Move to the dest point		*/
								LineTo(pt.h,pt.v);						/* Draw the line				*/
								lineison = 1;
								lastpt = pt;
							}
						}
					} /* end while mouse still down */
					if((precs[toplanet].owns == NOPLANET) || (!PtInRect(pt,&gamerect)))
					{
						if(lineison)
						{
							MoveTo(startpt.h,startpt.v);
							LineTo(lastpt.h,lastpt.v);
							lineison = 0;
						}
					}
					PenNormal();
					if((precs[toplanet].owns != NOPLANET) && (fmplanet != toplanet))
					{
						Show_To_Data();
						if(precs[fmplanet].owns == HUMAN)
						{
							Set_Up_Scroll();
							// Test for option key down here.
							// We could set up a "continuous feed" record
						}
						else
						{
							Show_Dist_Time();
						}
					}
				} /* end if selected rect contains a planet */
			}
		}

noloop:
	 
		if ((gamewind == whichWindow) &&  (code == inContent))
		{
		
			code = FindControl(myPt, whichWindow, &theControl);
			
			if ((code == inUpButton) || (code == inDownButton) || (code == inThumb) ||  (code == inPageDown) || (code == inPageUp))
				Do_A_ScrollBar(code,theControl,myPt);
			if (code != 0) 
				code = TrackControl(theControl,myPt, 0L);
			if (code == inButton)
				Do_A_Button(theControl);
		
		}
	}
	if(closeflag)
		Close_Galactic_Empire(gamewind,0L);
}

void
De_Select()
{
	Rect	r;
	GrafPtr	sp;

	GetPort(&sp);
	SetPort(gamewind);
	r.top = (precs[fmplanet].row * PLANETLENGTH) + 1;	/* Erase old selection */
	r.left = (precs[fmplanet].col * PLANETWIDTH) + 1;
	r.right = r.left + PLANETWIDTH;
	r.bottom = r.top + PLANETLENGTH;
	EraseRect(&r);
	if((precs[fmplanet].owns == HUMAN) && (precs[fmplanet].industry == 0))
	{
		DrawPicture ( planetPics[HUMAN0] , &r );
	}
	else
	{
		if((precs[fmplanet].owns == HUMAN) && (feedtolist[fmplanet] != (-1)))
		{
			DrawPicture ( planetPics[HUMANFEED] , &r );
		}
		else
		{
			DrawPicture ( planetPics[precs[fmplanet].owns] , &r );
		}
	}
	selected = 0;
	SetPort(sp);
}

Boolean
New_Select(short planet,Boolean showFeeder)
{
	Rect	r,r2;
	GrafPtr	sp;
	Boolean	skipDrawLoop = false;
	Boolean	drawFeeder = false;

	GetPort(&sp);
	SetPort(gamewind);
	r.top = (precs[planet].row * PLANETLENGTH) + 1;
	r.left = (precs[planet].col * PLANETWIDTH) + 1;
	r.right = r.left + PLANETWIDTH;
	r.bottom = r.top + PLANETLENGTH;
	EraseRect(&r);
	if((precs[planet].owns == HUMAN) && (precs[planet].industry == 0))
	{
		DrawPicture ( planetPics[HUMAN0] , &r );
	}
	else
	{
		if((precs[planet].owns == HUMAN) && (feedtolist[planet] != (-1)))
		{
			DrawPicture ( planetPics[HUMANFEED] , &r );
			if(showFeeder)drawFeeder = true;
		}
		else
		{
			DrawPicture ( planetPics[precs[planet].owns] , &r );
		}
	}
	selected = 1;
	fmplanet = planet;
	InsetRect(&r,1,1);
	FrameRect(&r);

	if(drawFeeder)
	{
		/* Turn off continuous after showing the feedto planet */
		
		toplanet = feedtolist[fmplanet];

		startpt.h = (r.left & 0xFFF0) + 8;
		startpt.v = (r.top & 0xFFFF0) + 8;

		r2.top = (precs[toplanet].row * PLANETLENGTH) + 1;
		r2.left = (precs[toplanet].col * PLANETWIDTH) + 1;
		r2.right = r2.left + PLANETWIDTH;
		r2.bottom = r2.top + PLANETLENGTH;
		
		lastpt.h = (r2.left & 0xFFF0) + 8;
		lastpt.v = (r2.top & 0xFFF0) + 8;

		PenPixPat(linePat);
		PenMode(patXor);

		MoveTo(startpt.h,startpt.v);			/* Move to the dest point		*/
		LineTo(lastpt.h,lastpt.v);						/* Draw the line				*/
		lineison = 1;
		
		PenNormal();

		// ���� PERHAPS ONLY TURN IT OFF IF OPTION KEY IS HELD DOWN OR DOUBLE_CLICK????	
		feedtolist[planet] = (-1);

		Show_To_Data();
		Set_Up_Scroll();
		skipDrawLoop = true;
	}

	SetPort(sp);

	return skipDrawLoop;
}

void
Launch_Ships(short nships,Boolean constantFeed,Boolean silentLaunch)
{
	Rect	r;

	gamesaved = 0;

	/* Set up a launch record here */

	if(nships > 0)
	{
		trecs[tottrecs].fromrow = precs[fmplanet].row;
		trecs[tottrecs].fromcol = precs[fmplanet].col;
		trecs[tottrecs].fromowns= precs[fmplanet].owns;
		trecs[tottrecs].torow   = precs[toplanet].row;
		trecs[tottrecs].tocol   = precs[toplanet].col;
		trecs[tottrecs].ships   = nships;
		trecs[tottrecs].timeleft= currtime;
		
		tottrecs++;
	}

	/* If constant, add it to the constant feed list */

	if(constantFeed)
	{
		/* Record this feed */
		feedtolist[fmplanet] = toplanet;	
	}
	else
	{
		feedtolist[fmplanet] = (-1);	
	}
	
	/* Update the window status */

	precs[fmplanet].ships -= nships;  

	if(!silentLaunch)
	{
		if(lineison)
		{
			PenPixPat(linePat);
			PenMode(patXor);
			MoveTo(startpt.h,startpt.v);
			LineTo(lastpt.h,lastpt.v);
			PenNormal();
			PenMode(patCopy);
			Disable_Scroll();
			lineison=0;
		}
		r = inforectall;
		InsetRect(&r,1,1);
		EraseRect(&r);
		Show_From_Data();
		if((precs[fmplanet].owns == HUMAN))
		{
			De_Select();
		}
	}
} 


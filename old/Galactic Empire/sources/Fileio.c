#include "Galaxy.h"
#include <stdio.h>


#define	CloseAlert		101
#define      I_No  		1
#define      I_Cancel  	2
#define      I_Yes  	3

#define Item_Fast_Battles	 2

static 	Point 			SFPwhere = { 100, 100 };
SFReply 				reply = {0};
extern	WindowPtr		gamewind;
extern	PlanetRec		precs[PLANETROWS*PLANETCOLS];
extern	TransRec		trecs[MAXTRANSRECS];
extern	short			feedtolist[PLANETROWS*PLANETCOLS];
extern	short			tottrecs;
extern	short			totplanets;
extern	short			elist[8];			/* Holds our enemy list */
extern	short			dlist[8];			/* Dead enemy list 		*/
extern	short			totenemies;			/* Count of our enemies */
extern	short			curryear;
extern	short			gamesaved;
extern	short			closeflag;
extern	short			fmplanet;
extern	short			selected;
extern	short			fastbattles;		/* Do fast battles if=1; */
extern	MenuHandle		GalaxyMenu;

extern	GubruRec		gubru;
extern	CzinRec			czin;
extern	ArachRec		arach;
extern	MutantRec		mutant;
extern	NukeRec			nuke;
extern	BozoRec			bozo;
extern  BotsRec			bots;

typedef	struct
	{
	short			tottrecs;
	short			totplanets;
	short			elist[8];			
	short			dlist[8];			
	short			totenemies;			
	short			currinput;
	short			curryear;
	short			fmplanet;
	short			selected;
	short			fastbattles;		/* Do fast battles if=1; */
	}GameRec;
	
/************************************************************************************
 *		Check if we need to save our game											*
 ************************************************************************************/
short
Check_Saved()
{
if((gamewind != 0L) && !gamesaved)
	{
	closeflag = 0;
	ParamText("\pSave this game? ","\p","\p","\p");
	switch(MyStopAlert(CloseAlert,0L))
		{
		case I_Cancel:
			return(1);
			break;
		case I_No:
			break;
		case I_Yes:
			if(Save_Galaxy())return(1);
			break;
		}
	reply.good = 0;
	}
return(0);
}
/************************************************************************************
 *		Save a game. Reached by selecting the Save function from the FILE menu		*
 ************************************************************************************/

void
Save_As_Galaxy()
{
SFReply 	sreply;
sreply = reply;
reply.good = 0;
if(Save_Galaxy())
	{
	reply = sreply;
	}
}

/************************************************************************************
 *		Save a game. Reached by selecting the Save function from the FILE menu		*
 ************************************************************************************/
short
Save_Galaxy()
{
SFReply 	sreply;
Str255		fn;
long		size;
short		i,ref;
GameRec		gr;

if(gamewind == 0L)return(0);
sreply = reply;
if(!reply.good)
	{
	pStrCopy("\pUntitled",fn);
	SFPutFile( SFPwhere,"\pSave as:",fn,0L,&reply);
	}
if(reply.good)
	{
	FSDelete(reply.fName,reply.vRefNum);
	Create(reply.fName,reply.vRefNum, 'Glxy', 'Gsve');
	FSOpen(reply.fName,reply.vRefNum, &ref);
	 
	gr.tottrecs = tottrecs;
	gr.totplanets = totplanets;
	gr.totenemies = totenemies;
	gr.curryear = curryear;
	gr.fmplanet = fmplanet;
	gr.selected = selected;
	gr.fastbattles = fastbattles;
	for(i=0;i<totenemies;i++)gr.elist[i] = elist[i];
	for(i=0;i<totenemies;i++)gr.dlist[i] = dlist[i];
	
	size = (long)sizeof(GameRec); 
	FSWrite( ref, &size, &gr);
	size = (long)sizeof(precs);		
	FSWrite( ref, &size, &precs[0]);
	size = (long)sizeof(trecs);		
	FSWrite( ref, &size, &trecs[0]);
	
/* Write enemy structures here */

	size = (long)sizeof(gubru);		
	FSWrite( ref, &size, &gubru);
	size = (long)sizeof(czin);		
	FSWrite( ref, &size, &czin);
	size = (long)sizeof(arach);		
	FSWrite( ref, &size, &arach);
	size = (long)sizeof(mutant);		
	FSWrite( ref, &size, &mutant);
	size = (long)sizeof(nuke);		
	FSWrite( ref, &size, &nuke);
	size = (long)sizeof(bozo);		
	FSWrite( ref, &size, &bozo);
	size = (long)sizeof(bots);
	FSWrite( ref, &size, &bots);

	size = (long)sizeof(feedtolist);		
	FSWrite( ref, &size, &feedtolist[0]);
	
		
	FSClose(ref);
	sreply = reply;
	gamesaved = 1;
	return(0);
	}
else
	{
	reply = sreply;
	}
return(1);
}
/************************************************************************************
 *		Open a file or document as a result of Finder input							*
 ************************************************************************************/

void 
Open_Finder_File(short dnum)
{
AppFile		ainfo;
FInfo		finf;
GetAppFiles(dnum,&ainfo);
GetFInfo(ainfo.fName,ainfo.vRefNum,&finf);
switch(ainfo.fType)
	{
	case 'Gsve':				/* A Galaxy save file */
		{
		if(finf.fdCreator != 'Glxy')goto badone;
		Get_Galaxy(ainfo.fName,ainfo.vRefNum,ainfo.fType);
		pStrCopy(ainfo.fName,reply.fName);
		reply.vRefNum = ainfo.vRefNum;
		reply.fType = ainfo.fType;
		reply.good = 1;
		break;
		}
	default:					/* We dont support this file type */
		{
badone:
		ParamText(ainfo.fName,"\p is not a Galactic Empire File.","\p","\p");
		MyStopAlert(STOPALRT,0L);
		}
	}
ClrAppFiles(dnum);
}

/************************************************************************************
 *		Open a file. Reached by selecting the OPEN function from the FILE menu		*
 ************************************************************************************/

void 
Open_Galaxy()
{
SFTypeList	myTypes;
SFReply 	reply;

myTypes[0]='Gsve';
SFGetFile( SFPwhere, "\p", 0L, 1, myTypes, 0L, &reply);
if (reply.good) 
	{
	Get_Galaxy(reply.fName,reply.vRefNum,reply.fType);
	}
}
/************************************************************************************
 *		Load a Galaxy file 															*
 ************************************************************************************/

void
Get_Galaxy(StringPtr fn,short vr,short /*ft*/)
{
short		i,ref;
long		size;
GameRec		gr;

// Set defaults for older saved games
for(i=0;i<PLANETROWS*PLANETCOLS;i++)
	{
	feedtolist[i] = (-1);
	}

FSOpen(fn,vr,&ref);
	 
size = (long)sizeof(GameRec); 
FSRead( ref, &size, &gr);

tottrecs = gr.tottrecs;
totplanets = gr.totplanets;
totenemies = gr.totenemies;
curryear = gr.curryear;
fmplanet = gr.fmplanet;
selected = gr.selected;
fastbattles = gr.fastbattles;
for(i=0;i<totenemies;i++)elist[i] = gr.elist[i];
for(i=0;i<totenemies;i++)
	{
	dlist[i] = gr.dlist[i];
	if(dlist[i])
		{
		Show_Dead_Alien(elist[i]);
		}
	}

size = (long)sizeof(precs);		
FSRead( ref, &size, &precs[0]);
size = (long)sizeof(trecs);		
FSRead( ref, &size, &trecs[0]);

/* Read enemy structures here */

size = (long)sizeof(gubru);		
FSRead( ref, &size, &gubru);
size = (long)sizeof(czin);		
FSRead( ref, &size, &czin);
size = (long)sizeof(arach);		
FSRead( ref, &size, &arach);
size = (long)sizeof(mutant);		
FSRead( ref, &size, &mutant);
size = (long)sizeof(nuke);		
FSRead( ref, &size, &nuke);
size = (long)sizeof(bozo);		
FSRead( ref, &size, &bozo);
size = (long)sizeof(bots);
FSRead( ref, &size, &bots);

size = (long)sizeof(feedtolist);
FSRead( ref, &size, &feedtolist[0]);

FSClose(ref);
gamesaved = 1;
CheckItem(GalaxyMenu, Item_Fast_Battles, fastbattles);

Open_Galactic_Empire(0L,0);
}

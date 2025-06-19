 
#include "Galaxy.h"
#include <stdlib.h>
#include <fp.h>

extern SHandle		saved_enemies;
extern	short		prefsRefNum;

void main()
{
	char          doneFlag;
	char          stillInGoAway;
	char          ch;
	short        code;
	short        theMenu,theItem;
	long         mResult;
	WindowPtr    whichWindow;
	EventRecord  myEvent;
	TEHandle     theInput;
	Rect         tempRect,OldRect;
	Point         myPt;
	GrafPtr       SavePort;
	short		oc;						/* Open/close finder flag */
	short		dcnt=0;					/* Finder document count */
	short		dnum=0;					/* Current Finder document (starts with 1 ) */
	short		openedfile = 0;

	 
	 

	InitGraf(&qd.thePort);
	InitFonts();
	FlushEvents(everyEvent,0);
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(0L);
	InitCursor();
	 
	doneFlag = FALSE;
	 
	InitMyMenus();
	Get_Saved_Data();
	 
	theInput = 0L;

	Init_Galactic_Empire();
	D_About_Galaxy(1);

		
	shutabort: 
	do
	{
		if (theInput != 0L) 
			TEIdle(theInput);
		SystemTask();
	 
	 
	 	srand((short)TickCount());		/* seed randowm number generator for aliens		*/

		if (GetNextEvent(everyEvent, &myEvent))	
		{
			code = FindWindow(myEvent.where, &whichWindow);	
	 
	 
			switch (myEvent.what)
			{
				case mouseDown:
					if (code == inMenuBar)
					{
						mResult = MenuSelect(myEvent.where);
						theMenu = HiWord(mResult);
						theItem = LoWord(mResult);
						HandleMenu(&doneFlag,theMenu,theItem,&theInput);
					}
	 
					if ((code == inDrag)&&(whichWindow != 0L))
					{
						 tempRect = qd.screenBits.bounds;
						 SetRect(&tempRect, tempRect.left + 10, tempRect.top + 25, tempRect.right - 10, tempRect.bottom - 10);
						 DragWindow(whichWindow, myEvent.where, &tempRect);
					}
	 
					if (code == inGrow)
					{
						SetPort(whichWindow);
	 
						myPt = myEvent.where;
						GlobalToLocal(&myPt);
	 
						OldRect.left = whichWindow->portRect.left;
						OldRect.right = whichWindow->portRect.right;
						OldRect.top = whichWindow->portRect.top;
						OldRect.bottom = whichWindow->portRect.bottom;
	 
						SetRect(&tempRect,15,15,(qd.screenBits.bounds.right - qd.screenBits.bounds.left), (qd.screenBits.bounds.bottom - qd.screenBits.bounds.top) - 20);
						mResult = GrowWindow(whichWindow, myEvent.where, &tempRect);
						SizeWindow(whichWindow, LoWord(mResult), HiWord(mResult), TRUE);
	 
	 
						SetPort(whichWindow);
	 
						SetRect(&tempRect, 0, myPt.v - 15, myPt.h + 15, myPt.v + 15); 
						EraseRect(&tempRect);
						InvalRect(&tempRect);
						SetRect(&tempRect, myPt.h - 15, 0, myPt.h + 15, myPt.v + 15);  
						EraseRect(&tempRect);
						InvalRect(&tempRect);
						DrawGrowIcon(whichWindow);
					}
	 
					if (code == inGoAway)
					{
						stillInGoAway = TrackGoAway(whichWindow,myEvent.where);
						if (stillInGoAway == TRUE)
						{
							switch (GetWRefCon(whichWindow)) 
							{ 
								case 1: 
									Close_Galactic_Empire(whichWindow,&theInput);
									break;
							}
						}
					}
	 
					if (code == inContent)
					{
						if (whichWindow != FrontWindow()) 
						{
							SelectWindow(whichWindow);
						}
						else
						{
							SetPort(whichWindow);
							switch (GetWRefCon(whichWindow)) 
							{ 
								case 1: 
									Do_Galactic_Empire (&myEvent,&theInput );
									break;
							}
						}
					}
	 
					if (code == inSysWindow)
					{
						SystemClick(&myEvent, whichWindow);
					}
	 
					if ((code == inZoomIn) || (code == inZoomOut))
					{
						if (whichWindow != 0L)
						{
							SetPort(whichWindow);
	 
							myPt = myEvent.where;
							GlobalToLocal(&myPt);
	 
							if (TrackBox(whichWindow, myPt, code) == TRUE)
							{
								ZoomWindow(whichWindow, code, TRUE);
								SetRect(&tempRect, 0, 0, 32000, 32000);
								EraseRect(&tempRect);
								InvalRect(&tempRect);
	 
							}
						}
					}
	 
					break;
	 
				case keyDown: 
				case autoKey: 
					ch = myEvent.message &  charCodeMask;
					if (myEvent.modifiers & cmdKey)
						{
						mResult = MenuKey(ch);
						theMenu = HiWord(mResult);
						theItem = LoWord(mResult);
						if (theMenu != 0) 
							HandleMenu(&doneFlag, theMenu, theItem, &theInput); 
						if (((ch == 'x') || (ch == 'X')) && (theInput != 0L)) 
							TECut(theInput);
						if (((ch == 'c') || (ch == 'C')) && (theInput != 0L)) 
							TECopy(theInput);
						if (((ch == 'v') || (ch == 'V')) && (theInput != 0L)) 
							TEPaste(theInput);
						}
					else if (theInput != 0L) 
						TEKey(ch,theInput);
					break;
	 
				case updateEvt:
					whichWindow = (WindowPtr)myEvent.message;
					GetPort(&SavePort);
					BeginUpdate(whichWindow);
					SetPort(whichWindow);
					switch (GetWRefCon(whichWindow)) 
					{ 
						case 1: 
							UpDate_Galactic_Empire(whichWindow);
							break;
					}
					EndUpdate(whichWindow);
					SetPort(SavePort);
					break;
	 
				case diskEvt:
					if (HiWord(myEvent.message) != 0) 
					{
						myEvent.where.h = ((qd.screenBits.bounds.right - qd.screenBits.bounds.left) / 2) - (304 / 2);
						myEvent.where.v = ((qd.screenBits.bounds.bottom - qd.screenBits.bounds.top) / 3) - (104 / 2);
						InitCursor();
						theItem = DIBadMount(myEvent.where, myEvent.message);
					}
					break;
	 
	 
				case activateEvt:
					if ((whichWindow != 0L) && (myEvent.modifiers & activeFlag))
					{ 
						SelectWindow(whichWindow);
					}
					break;
	 
	 
				default:
					break;
	 
			}
	 
		}
		Update_Menus();
	}
	while (doneFlag ==  FALSE);
	if(Check_Saved())
	{
		doneFlag = FALSE;
		goto shutabort;
	}
	ChangedResource((Handle)saved_enemies);
	UpdateResFile(prefsRefNum);
	FSClose(prefsRefNum); 
}

void
pStrCopy( StringPtr p1, StringPtr p2 )
/* copies a pascal string from p1 to p2 */
{
	register short len;
	
	len = *p2++ = *p1++;
	len = len &0xFF;
	while (--len>=0) *p2++ = *p1++;
}

void
pStrCat(StringPtr p1,StringPtr p2)
/* concatenates p1 onto the end of p2 */
{
	register	short	len1,len2;
	len1= (short)((unsigned char)*p1++);
	len2= (short)((unsigned char)*p2);
	*p2 = (unsigned char)(len1+len2);
	p2 += len2+1;
	while(--len1>=0) *p2++ = *p1++;
}
/* Return TRUE if string s1 = s2 */

short
pStrCmp(StringPtr s1,StringPtr s2)
{
	short	i;

	if(s1[0] != s2[0])return(0);
	for(i=1;i<=s1[0];i++)
		if(s1[i] != s2[i])return(0);
	return(1);
}
/************************************************************************************
 *		Convert a long to a HEX number												*
 ************************************************************************************/
void 
NumToHex(unsigned long n,StringPtr s)
{
	short		i;

	for(s[0]=i=8;i>0;i--,n=n>>4)s[i] = ((n&0x0f) + ((n&0x0f)>9 ? 0x37 :0x30));
}


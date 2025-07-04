/****************************************************************************************
 *									About_Galaxy.c										*
 *																						*
 *	Copyright � 1989 Blueridge Technologies, Inc. All right reserved.					*
 *																						*
 *	Author:	R.C. Landrum																*
 *	Date:	30 Jun 88																	*
 *																						*
 ****************************************************************************************/
/********************************************************************************
 *		Does the about dialog.													*
 ********************************************************************************/

#include "Galaxy.h"

static Rect		ebox = {150,150,164, 240 };

typedef struct	{
				unsigned char	vb1;		/* Part 1 of version in BCD 	*/
				unsigned char	vb23;		/* Parts 2 and 3 in BCD			*/
				unsigned char	stage;		/* 20=dev, 40=alpha, 60=beta, 80=release */
				unsigned char	build;		/* Build number in BCD			*/
				short			cntry;		/* Country (use 0)				*/
				Str255			svers;		/* Short version number '1.0'	*/
				Str255			lvers;		/* Long version number '1.0 Copyright.... */
				} VersRecord,**VersHandle;

void D_About_Galaxy(short splashflag)
{
	EventRecord     myEvent;
	DialogPtr      	dp;         						/* Dialog pointer			*/	
	GrafPtr			sp;									/* Saved port				*/
	short			id;
	Str255			name;
	VersHandle		vh;
	long			crap;
	
	GetPort( &sp );

//	if(splashflag)
//		{
//		PositionDialog('DLOG',6);
//		}  

	dp = GetNewDialog(6, 0,  (WindowPtr)-1L ); 			/* Bring in the dialog		*/

	ShowWindow( dp );

	SetPort( dp );

	DrawDialog( dp );
	
	vh = 0L;
	vh = (VersHandle)GetResource('vers',1);				/* Do we have a vers resource?	*/
	if(vh != 0L)
		{
		pStrCopy("\pVersion ",name);
		name[++name[0]] = (**vh).vb1 + 0x30;
		name[++name[0]] = '.';

		if(((**vh).vb23 >> 4) & 0x0F)
			{		
			name[++name[0]] = ((**vh).vb23 >> 4) + 0x30;
			if((**vh).vb23 & 0x0F)
				{
				name[++name[0]] = ((**vh).vb23 & 0x0F) + 0x30;
				}
			}
		else
			{
			name[++name[0]] = ((**vh).vb23 & 0x0F) + 0x30;
			}
		id=0;
		switch((**vh).stage)
			{
			case 0x20:	{name[++name[0]] = 'd';id=1;break;}
			case 0x40:	{name[++name[0]] = 'a';id=1;break;}
			case 0x60:	{name[++name[0]] = 'b';id=1;break;}
			}
		if(id && (**vh).stage)
			{
			name[++name[0]] = (**vh).build + 0x30;
			}
		EraseRect(&ebox);
		TextFont(geneva);
		TextSize(9);
		MoveTo(ebox.left,ebox.bottom);
		DrawString(name);
		}
			
	if(splashflag)
		{
		Delay(180L,&crap);
		}
	else
		{	    
		do {
			GetNextEvent( everyEvent, &myEvent );	
			} while (myEvent.what != mouseUp);
		}
	
	DisposeDialog( dp );       							/* Kill dialog				*/

	SetPort( sp );
      
}                                

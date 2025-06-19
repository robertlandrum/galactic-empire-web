/****************************************************************************************
 *									SaveData.c											*
 *																						*
 *	Copyright © 1989 Blueridge Technologies, Inc. All right reserved.					*
 *																						*
 *	Author:	R.C. Landrum																*
 *	Date:	5 Mar 89																	*
 *																						*
 ****************************************************************************************/
/************************************************************************************
 *		Creates or prepares the saved data resources.								*
 ************************************************************************************/
#include "Galaxy.h"
#include <Folders.h>
#include <Script.h>
#include <Resources.h>

SHandle		saved_enemies = 0L;
extern		short	fastbattles;

short		appvRefNum;
short		prefsVRefNum;
long		prefsDirID;
short		prefsRefNum = 0;

void 
Get_Saved_Data()
{
FSSpec	prefsFSS;
OSErr	err;
short	saveResFile = CurResFile();

GetVol(0L,&appvRefNum);

// Find our prefs file in the prefs folder

err = FindFolder(appvRefNum,kPreferencesFolderType, false, &prefsVRefNum, &prefsDirID);
if(err != noErr)goto skip;
err = FSMakeFSSpec(prefsVRefNum, prefsDirID, "\pGalactic Empire Prefs", &prefsFSS);
if(err != noErr)
	{
	// Must create file
	HCreateResFile(prefsVRefNum, prefsDirID, prefsFSS.name);
	}
prefsRefNum =  HOpenResFile(prefsVRefNum,prefsDirID, prefsFSS.name, fsRdWrPerm);
if(prefsRefNum == (-1))goto skip;

UseResFile(prefsRefNum);

skip:

saved_enemies=(SHandle)Get1Resource(SaveRType,SaveRID);
if(saved_enemies == 0L)
	{
	saved_enemies = (SHandle)NewHandle((long)sizeof(SRec));
	if(saved_enemies == 0L)
		{
		ParamText("\pCould not create saved data resource","\p","\p","\p");
		MyStopAlert(STOPALRT,0L);
		ExitToShell();
		}
	
	/* Initilize data to default values and create the new resource */
	
	/* Set default enemies	*/
	
	(**saved_enemies).dogubrus		=	1;
	(**saved_enemies).doczins		=	1;
	(**saved_enemies).doblobs		=	1;
	(**saved_enemies).dobots		=	1;
	(**saved_enemies).doarachs		=	1;
	(**saved_enemies).domutants		=	1;
	(**saved_enemies).donukes		=	1;
	(**saved_enemies).dobozos		=	1;
	(**saved_enemies).fastbattles	=	1;
		
	if(prefsRefNum != (-1))UseResFile(prefsRefNum);	
	AddResource((Handle)saved_enemies,SaveRType,SaveRID,"\pSaved Data");
	WriteResource((Handle)saved_enemies);
	
	}

UseResFile(saveResFile);	

/* Do any further preparation */

fastbattles = (**saved_enemies).fastbattles;
SetBattleMenu();
}

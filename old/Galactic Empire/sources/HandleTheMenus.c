#include "Galaxy.h"
#include "Menus.h"

/* Apple menu items */
#define Item_About_Galaxy  1

/* File menu items */
#define Item_New  1
#define Item_Open  2
#define Item_Close  4
#define Item_Save  5
#define Item_Save_As  6
#define Item_Quit  8

/* Galaxy menu items */
#define Item_Select_Enemies  1
#define Item_Fast_Battles	 2
#define	Item_Sound_Toggle	 3
#define Item_Show_Scores	 5

extern	MenuHandle   AppleMenu,FileMenu,GalaxyMenu;
extern	WindowPtr	gamewind;
extern	short		fastbattles;
extern	short		soundFlag;


void 
HandleMenu(char *doneFlag,short theMenu,short theItem,TEHandle   *theInput)
{

GrafPtr   SavePort;
Str255    DAName;
short     DNA;

	
	switch (theMenu)
		{
	
		case APPLEMENU:
			switch (theItem)
				{
				case Item_About_Galaxy:
					D_About_Galaxy(0);
					break;
				default:
					GetPort(&SavePort);
					GetItem(AppleMenu, theItem, DAName);
					DNA = OpenDeskAcc(DAName);
					SetPort(SavePort);
					break;
			 
				}
			break;
	
	
		case FILEMENU:
			switch (theItem)
				{
				case Item_New:
					Open_Galactic_Empire(theInput,1);
					break;
				case Item_Open:
					Open_Galaxy();
					break;
				case Item_Close:
					Close_Galactic_Empire(gamewind,theInput);					
					break;
				case Item_Save:
					Save_Galaxy();
					break;
				case Item_Save_As:
					Save_As_Galaxy();
					break;
				case Item_Quit:
					*doneFlag = TRUE;
					break;
				default:
					break;
			 
				}
			break;
	
	
		case GALAXYMENU:
			switch (theItem)
				{
				case Item_Select_Enemies:
					D_Enemies();
					break;
				case Item_Fast_Battles:
					if(fastbattles)
						{
						fastbattles=0;
						}
					else
						{
						fastbattles=1;
						}
					SetBattleMenu();
					break;
				case Item_Sound_Toggle:
					soundFlag ^= 1;
					SetSoundMenu();
					break;
				case Item_Show_Scores:
					Scores(SHOWSCORES);
					break;
				default:
					break;
			 
				}
			break;
	
		default:
			break;
	 
	}

HiliteMenu(0);
}

void
SetBattleMenu()
{
if(fastbattles)
	{
	CheckItem(GalaxyMenu, Item_Fast_Battles, 1);
	}
else
	{
	CheckItem(GalaxyMenu, Item_Fast_Battles, 0);
	}
}
void
SetSoundMenu()
{
if(soundFlag)
	{
	SetMenuItemText(GalaxyMenu, Item_Sound_Toggle, "\pSound Off");
	}
else
	{
	SetMenuItemText(GalaxyMenu, Item_Sound_Toggle, "\pSound On");
	}
}


void
Update_Menus()
{
if(gamewind == 0L)
	{
	EnableItem(FileMenu,Item_Open);
	EnableItem(FileMenu,Item_New);
	EnableItem(GalaxyMenu,Item_Select_Enemies);
	DisableItem(FileMenu,Item_Close);
	DisableItem(FileMenu,Item_Save);
	DisableItem(FileMenu,Item_Save_As);
	}
else
	{
	DisableItem(FileMenu,Item_Open);
	DisableItem(FileMenu,Item_New);
	DisableItem(GalaxyMenu,Item_Select_Enemies);
	EnableItem(FileMenu,Item_Close);
	EnableItem(FileMenu,Item_Save);
	EnableItem(FileMenu,Item_Save_As);
	}
}

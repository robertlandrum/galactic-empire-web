#include "Galaxy.h"


 

#define  I_OK   1
#define  I_Gubrus   9
#define  I_Czins   8
#define  I_Blobs   7
#define  I_Bots   6
#define  I_Mutants  5
#define  I_Arachs   4
#define  I_Nukes   3
#define  I_Bozos   2
#define  I_x   10
#define  I_Icon18   11
#define  I_Icon16   12
#define  I_Icon14   13
#define  I_Icon7   14
#define  I_Icon9   15
#define  I_Icon11   16
#define  I_Icon13   17
#define  I_Icon15   18
#define  I_Icon17   19
#define  I_Drawn_line1   20
#define  I_Drawn_line1_2   21
static char   ExitDialog; 
static char   DoubleClick; 
static Point   myPt; 

extern		SHandle	saved_enemies;

/* ======================================================== */
 
/* This is an update routine for non-controls in the dialog */ 
/* This is executed after the dialog is uncovered by an alert */ 
void  Refresh_Enemies_Dialog(DialogPtr    GetSelection) 
{ 
Rect    tempRect;
short    DType;
Handle    DItem;
 
	GetDItem(GetSelection,I_OK, &DType, &DItem, &tempRect);
	PenSize(3, 3);
	InsetRect(&tempRect, -4, -4);
	FrameRoundRect(&tempRect, 16, 16); 
	PenSize(1, 1); 
	
	/* Draw a line,  Drawn line1  */
	MoveTo(22,52);
	LineTo(303,52);
	
	/* Draw a line,  Drawn line1-2  */
	MoveTo(22,55);
	LineTo(303,55);
	
} 
 
/* ======================================================== */
 
 
void   
D_Enemies()
{
DialogPtr    GetSelection;
Rect    tempRect;
short    DType;
Handle    DItem;
ControlHandle    CItem;
short    itemHit,ecnt;
	 
	GetSelection = GetNewDialog(2, 0L, (WindowPtr)-1);
	ShowWindow(GetSelection);
	SelectWindow(GetSelection);
	SetPort(GetSelection);
	 
redo:	 
	/* Setup initial conditions */
	
	GetDItem(GetSelection,I_Gubrus, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).dogubrus);  
	
	GetDItem(GetSelection,I_Czins, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).doczins);  
	
	GetDItem(GetSelection,I_Blobs, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).doblobs);  
	
	GetDItem(GetSelection,I_Bots, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).dobots);  
	
	GetDItem(GetSelection,I_Mutants, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).domutants);  
	
	GetDItem(GetSelection,I_Arachs, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).doarachs);  
	
	GetDItem(GetSelection,I_Nukes, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).donukes);  
	
	GetDItem(GetSelection,I_Bozos, &DType, &DItem, &tempRect);
	CItem = (ControlHandle)DItem; 
	SetCtlValue(CItem, (**saved_enemies).dobozos);  
	
	Refresh_Enemies_Dialog(GetSelection); 
	 
	ExitDialog = FALSE; 
	 
	do
		{
		ModalDialog(0L, &itemHit); 
		GetDItem(GetSelection, itemHit, &DType, &DItem, &tempRect);
		CItem = (ControlHandle)DItem; 
		 
		/* Handle it real time */
		if (itemHit == I_OK )
			{
			/* ?? Code to handle this button goes here */
			ExitDialog =TRUE;
			Refresh_Enemies_Dialog(GetSelection); 
			}
		
		if (itemHit == I_Gubrus )
			{
			(**saved_enemies).dogubrus = GetCtlValue(CItem);
			(**saved_enemies).dogubrus = (**saved_enemies).dogubrus ^ 1;
			SetCtlValue(CItem, (**saved_enemies).dogubrus);
			}
		
		if (itemHit == I_Czins )
			{
			(**saved_enemies).doczins = GetCtlValue(CItem);
			(**saved_enemies).doczins = (**saved_enemies).doczins ^ 1;
			SetCtlValue(CItem, (**saved_enemies).doczins);
			}
		
		if (itemHit == I_Blobs )
			{
			(**saved_enemies).doblobs = GetCtlValue(CItem);
			(**saved_enemies).doblobs = (**saved_enemies).doblobs ^ 1;
			SetCtlValue(CItem, (**saved_enemies).doblobs);
			}
		
		if (itemHit == I_Bots )
			{
			(**saved_enemies).dobots = GetCtlValue(CItem);
			(**saved_enemies).dobots = (**saved_enemies).dobots ^ 1;
			SetCtlValue(CItem, (**saved_enemies).dobots);
			}
		
		if (itemHit == I_Mutants )
			{
			(**saved_enemies).domutants = GetCtlValue(CItem);
			(**saved_enemies).domutants = (**saved_enemies).domutants ^ 1;
			SetCtlValue(CItem, (**saved_enemies).domutants);
			}
		
		if (itemHit == I_Arachs )
			{
			(**saved_enemies).doarachs = GetCtlValue(CItem);
			(**saved_enemies).doarachs = (**saved_enemies).doarachs ^ 1;
			SetCtlValue(CItem, (**saved_enemies).doarachs);
			}
		
		if (itemHit == I_Nukes )
			{
			(**saved_enemies).donukes = GetCtlValue(CItem);
			(**saved_enemies).donukes = (**saved_enemies).donukes ^ 1;
			SetCtlValue(CItem, (**saved_enemies).donukes);
			}
		
		if (itemHit == I_Bozos )
			{
			(**saved_enemies).dobozos = GetCtlValue(CItem);
			(**saved_enemies).dobozos = (**saved_enemies).dobozos ^ 1;
			SetCtlValue(CItem, (**saved_enemies).dobozos);
			}
		
		
		 
		} 
	while (ExitDialog == FALSE);
	
		ecnt = 0;
		if((**saved_enemies).dogubrus)ecnt++;		
		if((**saved_enemies).doczins)ecnt++;		
		if((**saved_enemies).doblobs)ecnt++;		
		if((**saved_enemies).dobots)ecnt++;		
		if((**saved_enemies).doarachs)ecnt++;		
		if((**saved_enemies).domutants)ecnt++;		
		if((**saved_enemies).donukes)ecnt++;		
		if((**saved_enemies).dobozos)ecnt++;
		
		if(ecnt == 0)
			{
			ParamText("\pYou must select at least one opponent!","\p","\p","\p");
			MyStopAlert(STOPALRT,0L);
			goto redo;
			}
	DisposeDialog(GetSelection); 
	
}



#define		SaveRType		'Sdta'
#define		SaveRID			200

#define		ScoreType		'Scrs'
#define		ScoreRID		200

#define		INDEPENDENT		0
#define		HUMAN			1
#define		GUBRU			2
#define		CZIN			3
#define		BLOBS			4
#define		BOTS			5
#define		ARACHS			6
#define		MUTANTS			7
#define		NUKES			8
#define		BOZOS			9
#define		HUMAN0			10
#define		HUMANFEED		11
#define		NOPLANET		99

#define		ICONOFF			100			/* Add this to above Planet defs to get Planet ICON	*/

#define		STOPALRT		100

#define		APPLEMENU		1001
#define		FILEMENU		1002
#define		GALAXYMENU		1003

#define		PLANETCOLS		32		/* PLANETROWS * PLANETCOLS = Max planets we can have */
#define		PLANETROWS		27
#define		PLANETWIDTH		16
#define		PLANETLENGTH	16
#define		MAXTRANSRECS	3000	/* Max TransRecs we can have	*/

#define		SHOWSCORES		0
#define		CHECKSCORE		1

#define 	SETOWNED(p,n)	((p).everowned) |= (1<<(n-1))
#define		GETOWNED(p,n) 	((p).everowned) & (1<<(n-1))

typedef		struct {
  short		dogubrus;		/* Do this enemy if = 1	*/
  short		doczins;
  short		doblobs;
  short		dobots;
  short		doarachs;
  short		domutants;
  short		donukes;
  short		dobozos;
  short		fastbattles;	/* In fastbattles if=1	*/
} SRec,*SPtr,**SHandle;
		
typedef		struct {		
  Str255		names[5];
  short		years[5];
  short		ecount[5];
  Str255		elist[5];
} ScoreRec,*ScorePtr,**ScoreHandle;
		
typedef		struct {
  char		row;			/* Row the planet is on from 0 to 26	*/
  char		col;			/* Col the planet is on from 0 to 31	*/
  char		owns;			/* Who owns this planet (HUMAN, etc)	*/
  char		industry;		/* Industry level of this planet		*/
  char		homeplanet;		/* Its someones home planet if=1		*/
  char		humanpings;		/* Can see ships, etc if pings >= 3		*/
  short		ships;			/* Ships on this planet					*/
  short		lastvisit;		/* Last visited date					*/
  short		everowned;		/* =1 if we ever owned it				*/
} PlanetRec, *PlanetPtr;
		
typedef		struct {
  char		fromrow;		/* Ships coming from this row			*/
  char		fromcol;		/* Ships coming from this col			*/
  char		fromowns;		/* Who owns these ships					*/
  char		torow;			/* Ships going to this row				*/
  char		tocol;			/* Ships going to this col				*/
  short		ships;			/* Number of ships in transit			*/
  short		timeleft;		/* Time left to travel					*/
} TransRec, *TransPtr, **TransHandle;
		
typedef		struct {
  short		pcount;			/* planet count last turn				*/
  short		home;			/* the home planet						*/
  short		enemy;			/* my enemy								*/
} GubruRec;

typedef		struct {
  short		pcount;			/* planet count last turn				*/
  short		home;			/* the home planet						*/
  short		enemy;			/* my enemy								*/
  Boolean		homelost;		/* homeplant lost						*/
} CzinRec;

typedef		struct {
  short		pcount;			/* planet count last turn				*/
  short		home;			/* the home planet						*/
  short		enemy;			/* my enemy								*/
} ArachRec;

typedef		struct {
  short		pcount;			/* planet count last turn				*/
  short		home;			/* the home planet						*/
  short		enemy;			/* my enemy								*/
  short		ehome;			/* enemy home planet					*/
  short		stage;			/* staging planet						*/
} MutantRec;

typedef		struct {
  short		pcount;			/* planet count last turn				*/
  short		home;			/* the home planet						*/
  short		enemy;			/* my enemy								*/
  short		ehome;			/* enemy home planet					*/
  short		stage;			/* staging planet						*/
  short		next;			/* next planet to take					*/
  short		wait;			/* time to wait for intelligence		*/
  short		bored;			/* are we bored waiting					*/
  short		ndiv;			/* number of divisions in distance		*/
} NukeRec;

typedef		struct {
  short		home;			/* home planet							*/
  short		search[5];		/* next planets to attack				*/
  short		stage;			/* planet to stage from					*/
  short		next;			/* next planet to attack				*/
  short		wait;			/* time to wait							*/
} BozoRec;

typedef		struct {
  short		home;			/* home planet							*/
  short		enemy;
  short		ehome;
} BotsRec;

// Sound ('snd ') resource numbers

#define	kHumanLosesOwnHomePlanet	103
#define	kHumanCapturesHomePlanet	116
#define kCloseButNoCigar			131
#define	kLaunchOne					142
#define	kConstantFeed				143
#define	kLotsofCheers				513
#define kHumanHomePlanetHit			516
#define kNormalLaunch				525
#define	kHumansCaptureAPlanet		601
#define kNukersTakeAHomePlanet		658
#define kBozosTakeAHomePlanet		659
#define kBummer						520
#define kValkyries					517

// Prototypes

void 	main();
void	debug(StringPtr s,long l);
short	MyAlert(short theID,ModalFilterUPP theFilter);
short	MyNoteAlert(short theID,ModalFilterUPP theFilter);
short	MyStopAlert(short theID,ModalFilterUPP	theFilter);
void 	NumToHex(unsigned long n,StringPtr s);
void	PositionDialog( ResType theType,short theID);					
void	pStrCat(StringPtr p1,StringPtr p2);
short	pStrCmp(StringPtr s1,StringPtr s2);
void	pStrCopy(StringPtr p1,StringPtr p2 );

short	calc_dsquare( short p1, short p2 );
double	calc_distance( short p1, short p2 );
short	calc_time( short p1, short p2 );
void	send_ships( short f, short t, short s, short w );
void	StartASound(short sndRsrcNum);
void	EndASound();

short	Check_For_Dead(short enemy);
void	Show_Dead_Alien(short enemy);
void	Clear_Dead_Aliens();
void	Do_Attack_Fortify(short fr,short fc,short fown,short tr,short tc,short ships);
void	Do_Attack(short fp,short tp,short ships,short fown);
void	Do_Fortify(short tp,short tr,short tc,short ships,short fown);
short	Do_Battle();
void	Move_Arachs();
void	Move_Blobs();
void	Move_Bots();
void	Move_Mutants();
void	Move_Bozos();
void	Move_Czins();
void	Move_Gubrus();
void	Move_Nukes();
void	Restore_Bits();
void	Save_Bits(Rect *r);

void  	Refresh_Enemies_Dialog(DialogPtr    GetSelection); 
void   	D_Enemies();

void 	Open_Finder_File(short dnum);
short	Check_Saved();
void	Save_As_Galaxy();
short	Save_Galaxy();
void 	Open_Galaxy();
void	Get_Galaxy(StringPtr fn,short vr,short ft);

void 	 HandleWScrollBar (short   code, short   Start,short    Stop, 
						short   Increment, short   LIncrement, ControlHandle   theControl,Point   myPt);
void 	Do_A_ScrollBar(short   code,ControlHandle   theControl,Point   myPt);
void  	Do_A_Button(ControlHandle	theControl);
void  	Init_Galactic_Empire();
short 	Close_Galactic_Empire(WindowPtr  whichWindow,TEHandle *theInput);
void	Show_Visit();
void	Show_From_Data();
void	Show_To_Data();
void  	UpDate_Galactic_Empire(WindowPtr  whichWindow);
void	Show_Year();
void	Show_Input();
void	Show_Dist_Time();
void	Set_Home_Planet(short minrow,short mincol,short maxrow,short maxcol,short ptype);
void	Disable_Scroll();
void	Set_Up_Scroll();
void 	Open_Galactic_Empire(TEHandle	*theInput,short newgame);
void  	Do_Galactic_Empire(EventRecord	*myEvent, TEHandle	*theInput);
void	De_Select();
Boolean	New_Select(short planet,Boolean showFeedTo);
void	Launch_Ships(short nships,Boolean constantFeed,Boolean silentLaunch);
void	Calc_Time();

void 	HandleMenu(char *doneFlag,short theMenu,short theItem,TEHandle   *theInput);
void	SetBattleMenu();
void	SetSoundMenu();
void	Update_Menus();

void 	InitMyMenus();

void 	Get_Saved_Data();

void 	Scores(short req);
void	Erase_Scores();
void	Add_Score(short pos);

void D_About_Galaxy(short splashflag);


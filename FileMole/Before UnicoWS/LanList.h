////////////////////////////////////////////////////////////////////////////////
// LAN List messages

enum
{
	LLN_SELECT=1<<16,	// new item selected
	LLN_ENTER=2<<16,	// enter to deeper level
	LLN_EXIT=3<<16,		// exit to higher level
	LLN_OPEN=4<<16,		// open branch
	LLN_CLOSE=5<<16		// close branch
};

enum {
	LlvList=0,			// flat, single level list
	LlvListRecurse=1,	// flat, recursive list
	LlvTree=2			// indented, multilevel tree
};

////////////////////////////////////////////////////////////////////////////////
// types and structures

#define LanListMaxPath     1024 //up to 1k characters for current path (seems excessive, but may need for URLs)
#define LanListMaxDepth      16 //only 16 levels deep

typedef struct
{
	short* name;			//ptr to Unicode name
	union {
		unsigned int size;	//byte size of file (or maybe total bytes of files if container)
		unsigned int ip;	//IP address if server
		unsigned int serial;//volume serial number if drive
	};
	unsigned int timel;		//low dword of file modified date or network object last known access
	unsigned int timeh;		//high dword of file modified date or network object last known access
	unsigned int flags;		//bit flags for object type and attributes
	unsigned int next;		//next child index in parent's chain, NULL if last
	unsigned int child;		//index of first child if container, NULL if not
	unsigned int parent;	//child's parent index, NULL if in root
} LanListEl;

typedef enum
{
	LlfIndentMask=0x7F, //indent is lower byte

	// following flags can be combined (ORed)
	LlfEnumerated=128,	//container children enumerated, but maybe not subchildren
	LlfRecursed=256,	//container fully enumerated, whether network, workgroup, or server
	LlfVisible=512, //visible using current filter
	LlfInclude=1024,	//item matches inclusion mask
	LlfExclude=2048,	//item is excluded
	LlfOpen=4096,	//container is currently open (branch is open)
	LlfDenied=8192, //access denied, password probably required
	LlfError=16384,	//server down, resource offline, share removed, file deleted
	LlfRedraw=32768, //item needs redrawing
	LlfDeleted=65536, //item removed because no longer exists
	LlfNew=131072, //item newly added since last scan
	LlfContainer=262144, //item is a container, not a file, printer, or unknown
	LlfFavorite=524288,
	LlfChanged=1048576, //existing item changed (size/date attributes modified)
	LlfNull=2097152, //item has been removed from list, all other attributes must be ignored
	LlfSelected=4194304, //item selected for multiple selection mode
	LlfIgnore=8388608, //ignore item, don't enumerate (for someone who shares their whole HD)

	// following can NOT be combined
	LlfGeneric=RESOURCEDISPLAYTYPE_GENERIC<<24, //0
	LlfDomain=RESOURCEDISPLAYTYPE_DOMAIN<<24, //1
	LlfServer=RESOURCEDISPLAYTYPE_SERVER<<24, //2
	LlfShare=RESOURCEDISPLAYTYPE_SHARE<<24, //3
	LlfFile=RESOURCEDISPLAYTYPE_FILE<<24, //4
	LlfGroup=RESOURCEDISPLAYTYPE_GROUP<<24, //5
	LlfNetwork=RESOURCEDISPLAYTYPE_NETWORK<<24, //6
	LlfRoot=RESOURCEDISPLAYTYPE_ROOT<<24, //7
	LlfShareAdmin=RESOURCEDISPLAYTYPE_SHAREADMIN<<24, //8
	LlfFolder=RESOURCEDISPLAYTYPE_DIRECTORY<<24, //9
	LlfTree=RESOURCEDISPLAYTYPE_TREE<<24, //10
	LlfNdsContainer=RESOURCEDISPLAYTYPE_NDSCONTAINER<<24, //11

	LlfPrinter=12<<24, //network printer
	LlfComputer=13<<24, //all local drives
	LlfDrive=14<<24, //single drive (A: C: D:)
	LlfVolume=15<<24, //unique volume

	LlfTypeMax=15<<24,
	LlfTypeShift=24,
	LlfTypeMask=-1<<24
} LanListFlag;

typedef enum //these MUST be in the same order as the LAN list flags
{
	LliGeneric=0, //0
	LliDomain, //1
	LliServer, //2
	LliShare, //3
	LliFile, //4
	LliGroup, //5
	LliNetwork, //6
	LliRoot, //7
	LliShareAdmin, //8
	LliFolder, //9
	LliTree, //10
	LliNdsContainer, //11

	LliPrinter, //12
	LliComputer, //13
	LliDrive, //14
	LliVolume, //15

	// the following are special status overlays
	LliLock, //access denied
	LliIgnore, //ban server from being enumerated
	LliError, //server offline or unknown access error
	LliDeleted, //item deleted since last scan
	LliNew, //new item found not scanned before
	LliChanged, //changed item (either new date or size)
	LliAscending, //ascending order column
	LliDescending, //descending order column
	LliBlank, //unordered column
	LliTotal
};

// This structure holds the string of the complete current path
// (c:\media;\\peekin\music\midi\Ecuador.mid;ftp://www.orst.edu)
// and the full chain of ptrs leading from the top of the tree to
// the current path's list element.
typedef struct
{
	unsigned int depth;					//level of depth 0 to max
	unsigned int plen;					//character length of path string
	unsigned int child[LanListMaxDepth];//list index of each child
	unsigned int plens[LanListMaxDepth];//string length for each child
	short path[LanListMaxPath];			//Unicode path string
	char  pathA[LanListMaxPath];		//ANSI path string (here for convenience)
} LanListPath;

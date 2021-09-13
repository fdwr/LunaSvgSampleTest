////////////////////////////////////////////////////////////////////////////////
// Attribute List messages

enum
{
	ALN_CLICKED=0<<16,	// button was clicked, toggle, or new choice
	ALN_CONTEXT=1<<16,	// context menu opened (lParam is actually menu handle, not self)
	ALN_CHOICES=2<<16	// choice menu opened 
};

enum // menu commandidentifiers
{
	IDAL_PASTE=256, // paste text into edit
	IDAL_COPY, // copy item text or label
	IDAL_COPYALL, // copy all text in attribute list
	IDAL_CLEAR, // clear text from edit
	IDAL_COMMAND, // do button command
	IDAL_TOGGLE,  // switch toggle value
	IDAL_HELP, // get help on selected item
	IDAL_MAX=300 // no IDs will be above this
};


////////////////////////////////////////////////////////////////////////////////
// Attribute List defs

typedef struct
{
	unsigned int flags;	//misc item flags indicating type, options, and id
	unsigned int icon;	//index of icon in image list
	LPWSTR label;		//text description (Unicode)
	LPWSTR text;		//value string (Unicode)
} AttribListItem;

typedef struct
{
	unsigned int total; //total attribute items (including disabled and separators)
	unsigned int selected; //currently selected item
	unsigned int top; //item at scroll top
	HIMAGELIST himl; //handle to prefilled image list
	AttribListItem al[]; //array of attribute list items
} AttribList;

typedef enum
{
	AlfIdMask=0x0000FFFF,

	AlfDisabled=1<<16, // item shown grayed but not selectable or editable
	AlfHidden=1<<17, // item hidden and neither shown nor selectable
	AlfRedraw=1<<18, // item needs redrawing next WM_PAINT

	AlfTypeMask=0x00380000, // 3 bits allow 8 types
	AlfTypeRs=19,
	AlfSeparator=0<<19, // blank space between items
	AlfTitle=1<<19, // main list title bar or section divider
	AlfEdit=2<<19, // editable text prompt
	AlfButton=3<<19, // simple push button
	AlfToggle=4<<19, // toggle button with checked/unchecked
	AlfMenu=5<<19, // multichoice menu
	AlfLabel=6<<19, // filename prompt

	// toggle and menu types
	AlfNoCheckImage=1<<22,
	AlfChecked=1<<24, //button is checked
	AlfCheckedRs=24,
	AlfCheckedMask=255<<24,

	// edit type
	AlfNumeric=1<<22, //text edit accepts numbers only
	AlfLengthRs=24, //for text edit, tells maximum length
	AlfLengthMask=255<<24,

	AlfTitleType=AlfTitle|AlfDisabled,
	AlfSeparatorType=AlfSeparator|AlfDisabled,
};

#define AlfMenuValue(value) (value<<AlfCheckedRs)
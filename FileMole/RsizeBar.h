////////////////////////////////////////////////////////////////////////////////
// Resize Bar messages

enum
{
	RSZM_SET=WM_USER+16,

	// parent notification
	RSZN_CLICK=0<<16,	// bar was single clicked
	RSZN_START=1<<16,	// bar grabbed
	RSZN_STOP=2<<16,	// bar released after move
	RSZN_SIZE=3<<16		// bar moved
};

////////////////////////////////////////////////////////////////////////////////
// Resize Bar defs

typedef struct
{
	int min; //minimum x/y position
	int max; //maximum x/y position
	int track; //current track position (if any)
} RSZN_ITEM;
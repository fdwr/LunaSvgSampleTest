/**
Author:	Dwayne Robinson
Date:	2005-11-15
Since:	2005-11-15
Remark:	External variables (to avoid D's silliness with multiple definitions)
// TODO: DELETE THIS FILE, ONCE THE STYLE MAKER TOOL IS FINISHED
// THIS FILE IS A TEMP HACK SINCE DMD CAN'T IMPORT EXTERNAL
// REFERENCES WITHOUT LINKER ERRORS.
*/
module plain.plainstyledata;

private import pgfx.pgfxdefs;

////////////////////////////////////////////////////////////////////////////////

extern (C) PgfxLayer PlainButton_Layers;
extern (C) PgfxLayer PlainWindowBg_Layers;
extern (C) PgfxLayer PlainEdit_Layers;
extern (C) PgfxLayer PlainEditCaret_Layers;
extern (C) PgfxLayer PlainList_Layers;
extern (C) PgfxLayer PlainListSelect_Layers;
extern (C) PgfxLayer PlainMenu_Layers;
extern (C) PgfxLayer PlainMenuSelect_Layers;

extern (C) PgfxLayer PlainImage_Layers1;	// temp hack, probably load from file later
extern (C) PgfxLayer PlainImage_Layers2;	// temp hack, probably load from file later
extern (C) PgfxLayer PlainImage_Layers3;	// temp hack, probably load from file later

/**
\file	TransFrame.h
\author	Dwayne Robinson
\since	2005-07-06
\date	2005-07-06
\brief	Transparent frame to contain other controls but show background.
*/

#pragma once
//#include "commctrl.h"

#ifdef __STDC__
#define _C_
#endif
#ifdef __cplusplus
#define _C_
#endif
#ifdef _MSC_VER
#define _C_
#endif
//#else __NASM__ ...

#ifdef _C_
////////////////////////////////////////////////////////////////////////////////
// Attribute List messages

#ifdef  UNICODE
#define TransFrameClass TransFrameClassW
#else
#define TransFrameClass TransFrameClassA
#endif

//enum
//{
//};

////////////////////////////////////////////////////////////////////////////////
// Attribute List defs

//#pragma warning(disable: 4200) // nonstandard extension used : zero-sized array in struct/union
//#pragma pack(push, 1)     // for byte alignment
//typedef struct
//{
//} something;

//typedef struct
//{
//	type variable[]; //array of attribute list items
//} structname;
//#pragma pack(pop)     // no more byte alignment

#ifndef transframe_c
extern "C" WNDCLASS wcTransFrame;
#endif

#else // assembler

////////////////////////////////////////////////////////////////////////////////
// Attribute List messages

//const equ 0 ;

////////////////////////////////////////////////////////////////////////////////
// Attribute List defs

//struc AttribListItem
//.var:		resd 1	;
//endstruc
#endif


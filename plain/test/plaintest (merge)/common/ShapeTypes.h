// file:	ShapeTypes.h
// purpose: Shape structures
// author:	Dwayne Robinson
// date:	2005-05-30
// change:	2005-07-19

// * this custom version should not replace the remeshing project's version *

////////////////////////////////////////////////////////////////////////////////

#pragma once
#ifndef ShapeTypes_h
#define ShapeTypes_h

#include "icVector.h"

typedef union Vertex {
	double array[3];
	struct {
		double x,y,z;
	};
	/*
	float nx,ny,nz;			// Ignore these unknown variables for now.
							// I don't know what they are used for, but
							// they are NOT the normal :/
	//void *other_props;    // other properties
	icVector3 normal;
	union {					// added 20050112 for coloring individual vertexes
		struct {
			unsigned char red;
			unsigned char green;
			unsigned char blue;
			unsigned char alpha;
		};
		int color;
	};
	*/
} Vertex;

// vertex index, normal, texture...
typedef struct VintList {
	int vert;				// vertex index
	int norm;				// normal index
	int texc;				// texture coordinate index
} VintList;

typedef struct Face {
	unsigned char nverts;	// number of vertex indices in list (same for texes and norms)
	/*
	int *verts;				// vertex index list
	int *norms;				// normals index list
	int *texes;				// texture map coords index list
	*/
	VintList* vints;
	/*
	int *edges;              // edge index list (same number and order as verts)
	//void *other_props;       // other properties
	float area;
	icVector3 normal;
	//double length[3], angle[3];
	//icVector3 center;
	union {						// added 20050112 for coloring faces
		struct {
			unsigned char red;
			unsigned char green;
			unsigned char blue;
			unsigned char alpha;
		};
		int color;
	};
	*/
} Face;

/*
typedef struct Edge {
	//int index;					// numeric id, redundant
	int verts[2];				// vertex index list
	int faces[2];
} Edge;
*/

/*
typedef struct Tensor {
	icVector3 xvect;
	icVector3 yvect;
	icVector3 efg;
	icVector2 min;
	icVector2 max;
} Tensor;
*/

/*
// simple temporary structure
// created for the conversion from
// faces to edges.
// forms a linked list of vertexes.
typedef struct VertexEdgeChain {
	int vertex; // vertex id 
	int edge;	// edge id
	int next;	// next element in chain
} VertexEdgeChain;
*/

/*
typedef struct Corner {
	int p;	// previous corner
	int n;	// next corner
	int o;	// opposite corner on adjacent face
	int v;	// which vertex corner is part of
	int e;	// edge opposite to corner
	//int f;// which face corner is part of
} Corner;
*/

/* //-
typedef struct Patch{
	int level; // progressive depth
	int seedFace; // the 'representive' to originate the patch from (face index)
	int start; // first entry in the face table (lowest ftable index)
	int range; // number of faces in patch (from first to range-1)
	int next; // next sibling patch at this level (patch index, -1 if no more)
	int child; // first child patch (patch index, -1 if none)
	int color; // why not throw this in here too for convenience
} Patch;
*/

#endif

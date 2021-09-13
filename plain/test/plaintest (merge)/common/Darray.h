/**
\file	Darray.h
\author	Dwayne Robinson
\date	2005-09-05
\since	2004-05-31
*/

#pragma once
#ifndef Darray_h
#define Darray_h

// force standard C malloc for this project
#define DarrayForceMalloc

#define DarrayUseCpp

#if !defined(__cplusplus) && !defined(bool)
typedef unsigned char bool; // define the same as C++ does
#endif

#ifdef DarrayUseCpp  // use C++ class
	#ifndef __cplusplus
		#error "DarrayUseCpp was defined, but compiler is not using C++ mode. Ensure file is cpp."
	#endif
	class Darray {
	public:
		union {
			void* pv; // pointer to (pointer to data)
			char* pb;
			unsigned char* pub;
			short* ps;
			unsigned short* pus;
			int* pi;
			unsigned int* pui;
			float* pf;
			double* pd;
		};
		int granularity;	// entries per realloc
		int length;			// number of entries. Not actually needed by the
							// code. Just here for convenience.
		int size;			// byte size of whole array (not including these
							// vars). It is public for your information
							// convenience, but do NOT modify it.
	private:
		// this one is private because (a) once you create an array, its
		// type should not change and (b) only the allocator should touch the
		// actual byte size.
		int elsize; // byte size of each element (array index)

	public:
		bool init(void* pv, int granularity, int elsize);
		void free();
		bool grow(int entries);
		bool growPtr(int entries, void** ppv);
		bool growByOne();
		bool shrink(int entries);
		bool compact();
		bool insert(int entry, void* pitem);
		bool remove(int entry); // SHOULD be named delete, but tis reserved
	};

	#ifdef Darray_cpp
		#define api(name) Darray::##name
		#define param
		#define paramnc // parameter with no comma
		#define paramnt // parameters with no type
	#endif

#else // use C struct
	#ifdef __cplusplus
	extern "C" {
	#endif

	typedef struct {
		union {
			void* pv; // pointer to (pointer to data)
			signed char* pb;
			unsigned char* pub;
			short* ps;
			unsigned short* pus;
			int* pi;
			unsigned int* pui;
			float* pf;
			double* pd;
		};
		int size; // byte size of whole array (not including these vars)
		int granularity; // entries per realloc
		int elsize; // byte size of each element (array index)
	} Darray;

	bool Darray_init(Darray* dap, void* pv, int granularity, int elsize);
	void Darray_free(Darray* dap);
	bool Darray_grow(Darray* dap, int entries);
	bool Darray_growPtr(Darray* dap, int entries, void** ppv);
	bool Darray_growByOne();
	bool Darray_shrink(Darray* dap, int entries);
	bool Darray_compact(Darray* dap);
	bool Darray_insert(Darray* dap, int entry, void* pitem);
	bool Darray_remove(Darray* dap, int entry);

	#ifdef Darray_cpp
		#define api(name) Darray_##name
		#define param  Darray* dap,
		#define paramnc Darray* dap // parameter with no comma
		#define paramnt dap, // parameter with no type
		#define this dap
	#endif

	#ifdef __cplusplus
	}
	#endif
#endif

#endif

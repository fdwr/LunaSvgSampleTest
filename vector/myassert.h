// 

#undef  assert
#undef  assertbreak

#ifdef  NDEBUG
	#define assert(_Expression)      ((void)0)
	#define assertbreak(_Expression)  ((void)0)
#else
	#ifdef  __cplusplus
	extern "C" {
	#endif

	//void __cdecl myassert(const wchar_t* _Message, const wchar_t* _File, unsigned int _Line);
	void __cdecl myassert(const wchar_t* _Message, const wchar_t* _File, unsigned int _Line, const wchar_t* _Function);

	#ifdef  __cplusplus
	}
	#endif

	#ifndef _CRT_WIDE
	#define __CRT_WIDE(_String) L ## _String
	#define _CRT_WIDE(_String) __CRT_WIDE(_String)
	#endif

	#if defined(_MSC_VER)
		#define assert(_Expression) (void)( (!!(_Expression)) || (myassert(_CRT_WIDE(#_Expression), _CRT_WIDE(__FILE__), __LINE__, _CRT_WIDE(__FUNCTION__)), __debugbreak(), 0) );
	#else
		#define assert(_Expression) (void)( (!!(_Expression)) || (myassert(_CRT_WIDE(#_Expression), _CRT_WIDE(__FILE__), __LINE__, _CRT_WIDE(__FUNCTION__)), __asm { int 3 }, 0) ); 
	#endif

	#if defined(_MSC_VER)
		#define assertbreak(_Expression) (void)( (!!(_Expression)) || (__debugbreak(), 0) );
	#else
		#define assertbreak(_Expression) (void)( (!!(_Expression)) || (__asm { int 3 }, 0) ); 
	#endif
#endif

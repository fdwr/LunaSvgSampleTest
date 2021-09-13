#ifdef MYDEBUG
 extern void debuginit();
 extern void debugwrite(char* Message, ...);
 extern void debugflush();
 extern void debugfinish();
 extern void debugerror();
 //extern char debugwrite_Buffer[256];
#else
 #define debuginit() //
 #define debugwrite() //
 #define debugflush() //
 #define debugfinish() //
 #define debugerror() //
#endif

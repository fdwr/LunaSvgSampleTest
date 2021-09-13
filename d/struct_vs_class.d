module dtests;

//import std.c.windows.windows;

alias byte testType;

align(1) struct SomeStruct {
	testType var1, var2, var3;

	void showInfo()
	{
		printf("SomeStruct.showInfo\r\n");
		printf("\tsizeof=%d \r\n", SomeStruct.sizeof);
		printf("\tv1ofs=%d \r\n", SomeStruct.var1.offsetof);
		printf("\tv3ofs=%d \r\n", SomeStruct.var3.offsetof);
		printf("\tv3ofs+v3siz=%d \r\n", SomeStruct.var3.offsetof + SomeStruct.var3.sizeof);
		printf("\r\n");
	}

}

class SomeClass {
public:
	testType var1, var2, var3;

	void showInfo()
	{
		printf("SomeClass.showInfo \r\n");
		printf("\tsizeof=%d \r\n", SomeClass.sizeof);
		printf("\tv1ofs=%d \r\n", SomeClass.var1.offsetof);
		printf("\tv3ofs=%d \r\n", SomeClass.var3.offsetof);
		printf("\tv3ofs+v3siz=%d \r\n", SomeClass.var3.offsetof + SomeClass.var3.sizeof);
		printf("\tv3ofs+v3siz=%d \r\n", var3.offsetof + var3.sizeof);
		printf("\r\n");
	}

}

SomeStruct ss1;
SomeClass  sc1;

int main(char[][] args)
{
	sc1 = new typeof(sc1)();

	ss1.showInfo();
	sc1.showInfo();
	showInfo();

    return 0;

}

void showInfo()
{
	//printf("sizeof = %d \r\n", SomeStruct.var1.offsetof); <- gives error !@#?
	printf("main.showInfo \r\n");

	// SomeStruct. does work
	printf("\tSomeStruct.sizeof = %d \r\n", SomeStruct.sizeof);
	printf("\tSomeStruct.v1ofs  = %d \r\n", SomeStruct.var1.offsetof);
	printf("\tSomeStruct.v3ofs  = %d \r\n", SomeStruct.var3.offsetof);
	printf("\tSomeStruct.v3ofs+SomeStruct.v3siz = %d \r\n", SomeStruct.var3.offsetof + SomeStruct.var3.sizeof);
	printf("\r\n");

	// SomeClass. does not work
	printf("\tSomeClass.sizeof = %d \r\n", SomeClass.sizeof);
	/*******
	printf("\tSomeClass.v1ofs  = %d \r\n", SomeClass.var1.offsetof);
	printf("\tSomeClass.v3ofs  = %d \r\n", SomeClass.var3.offsetof);
	printf("\tSomeClass.v3ofs+SomeClass.v3siz = %d \r\n", SomeClass.var3.offsetof + SomeClass.var3.sizeof);
	*******/
	printf("\tSomeClass.v1ofs  = <compile error> :-/ \r\n");
	printf("\tSomeClass.v3ofs  = <compile error> :-/ \r\n");
	printf("\tSomeClass.v3ofs+SomeClass.v3siz = <compile error> :-/ \r\n");
	printf("\r\n");

	// ss1. does not work
	printf("\tss1.sizeof = %d \r\n", ss1.sizeof);
	/*******
	printf("\tss1.v1ofs  = %d \r\n", ss1.var1.offsetof);
	printf("\tss1.v3ofs  = %d \r\n", ss1.var3.offsetof);
	printf("\tss1.v3ofs+ss1.v3siz = %d \r\n", ss1.var3.offsetof + ss1.var3.sizeof);
	*******/
	printf("\tss1.v1ofs  = <compile error> :-/ \r\n");
	printf("\tss1.v3ofs  = <compile error> :-/ \r\n");
	printf("\tss1.v3ofs+ss1.v3siz = <compile error> :-/ \r\n");
	printf("\r\n");

    // sc1. does work
	printf("\tsc1.sizeof = %d \r\n", sc1.sizeof);
	printf("\tsc1.sizeof = %d \r\n", null.sizeof);
	printf("\tsc1.v1ofs  = %d \r\n", sc1.var1.offsetof);
	printf("\tsc1.v3ofs  = %d \r\n", sc1.var3.offsetof);
	printf("\tsc1.v3ofs+sc1.v3siz = %d \r\n", sc1.var3.offsetof + sc1.var3.sizeof);
	printf("\r\n");

	// typeof(ss1). does work
	printf("\ttypeof(ss1).sizeof = %d \r\n", typeof(ss1).sizeof);
	printf("\ttypeof(ss1).v1ofs  = %d \r\n", typeof(ss1).var1.offsetof);
	printf("\ttypeof(ss1).v3ofs  = %d \r\n", typeof(ss1).var3.offsetof);
	printf("\ttypeof(ss1).v3ofs+typeof(ss1).v3siz=%d \r\n", typeof(ss1).var3.offsetof + typeof(ss1).var3.sizeof);
	printf("\r\n");

    // typeof(sc1). does not work
	printf("\tsizeof = %d \r\n", typeof(sc1).sizeof);
	/*******
	printf("\tv1ofs  = %d \r\n", typeof(sc1).var1.offsetof);
	printf("\tv3ofs  = %d \r\n", typeof(sc1).var3.offsetof);
	printf("\tv3ofs+v3siz = %d \r\n", typeof(sc1).var3.offsetof + typeof(sc1).var3.sizeof);
	*******/
	printf("\tv1ofs  = <compile error> :-/ \r\n");
	printf("\tv3ofs  = <compile error> :-/ \r\n");
	printf("\tv3ofs+v3siz = <compile error> :-/ \r\n");
	printf("\r\n");

	printf("int.siz=%d\r\n", int.sizeof);
	printf("float.siz=%d\r\n", float.sizeof);
	printf("double.siz=%d\r\n", double.sizeof);
	printf("long.siz=%d\r\n", long.sizeof);
	printf("bool.siz=%d\r\n", bool.sizeof);
	printf("bit.siz=%d\r\n", bit.sizeof);

}


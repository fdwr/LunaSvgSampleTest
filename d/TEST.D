/*
Random test program
*/

module dtests;

import std.c.windows.windows;

//extern (C) {
//	int SomeFunc();
//}

enum FruitBaseTypes {
	YourTypicalFruitBaseType,
}

enum FruitTypes : FruitBaseTypes {
	Orange=2,
	Apple=1,
	Pear,
	Pineapple,
}


/*
struct BaseStruct {
	int WhyCantStructsHaveBases;
}

struct ChildStruct : BaseStruct {
	int BecauseTheyWouldBeSoUseful;
	int JustSingleInheritance;
	int NoVirtualFunctions;
}
*/

version(Windows) {
	int somevar = 1;
}

struct Abc {
        int a;
        int b;

		static if (FruitTypes.Orange == 1) {
        	int Blah() { if (this == null) return 1; else return 0; }
        }
       	int anotherSum() { return b; };
        int totalSum(int val) { return val+1+a+anotherSum(); };
}

struct Def  {
        Abc x;
        int d;
        int e;
}

struct SomeStruct {
	int var1;
	int var2;
	int var3;

	void showInfo()
	{
		printf("SomeStruct.showInfo\r\n");
		printf("\tsizeof=%d \r\n", SomeStruct.sizeof);
		printf("\tv1ofs=%d \r\n", SomeStruct.var1.offsetof);
		printf("\tv3ofs=%d \r\n", SomeStruct.var3.offsetof);
		printf("\tv3ofs+v3siz=%d \r\n", SomeStruct.var3.offsetof + SomeStruct.var3.sizeof);
		static if (FruitTypes.Orange > 2) {
			printf("why can't static if be global");
		}
	}

}

class SomeClass {
public:
	int var1;
	int var2;
	int var3;

	void showInfo()
	{
		printf("SomeClass.showInfo \r\n");
		printf("\tsizeof=%d \r\n", SomeClass.sizeof);
		printf("\tv1ofs=%d \r\n", SomeClass.var1.offsetof);
		printf("\tv3ofs=%d \r\n", SomeClass.var3.offsetof);
		printf("\tv3ofs+v3siz=%d \r\n", SomeClass.var3.offsetof + SomeClass.var3.sizeof);
	}

}

struct SomeArrayStruct {
	union {
	    struct {
	    	wchar[1] els;
	    	//int els2 = 3;
	    	wchar[] els2;
	    }
		struct {
		    int[5] ints;
		}
	}
}


Abc test;

SomeStruct ss1;
SomeClass  sc1;

SomeArrayStruct sas1;

int main(char[][] args)
{
/*
    printf("hello world\n");
    printf("args.length = %d\n", args.length);
    for (int i = 0; i < args.length; i++)
        printf("args[%d] = '%s'\n", i, cast(char *)args[i]);
*/
	int abx = test.totalSum(5);
	float fnum;
	int inum = cast(int)fnum;
    sc1 = new typeof(sc1)();
	SomeClass sc2();

	const static char[] msg = "Testing\0";
	const static char[] title = "Title\0";
	ss1.showInfo();
	sc1.showInfo();
        showInfo();

	//printf("=%d \r\n", sc1.sizeof);
	MessageBoxA(null, msg, title, 0);

	//SomeFunc();
    return 0;

}

//static byte c[10];

void showInfo()
{
	//printf("sizeof=%d \r\n", SomeStruct.var1.offsetof); <- gives error !@#?
	printf("main.showInfo \r\n");

	printf("SomeStruct:\r\n");
        printf("\tv1ofs=%d \r\n", SomeStruct.var1.offsetof);
        //printf("\tsizeof=%d \r\n", ss1.sizeof);
        //printf("\tv1ofs=%d \r\n", ss1.var1.offsetof); // <- why not !@#?
	//printf("\tv3ofs=%d \r\n", ss1.var3.offsetof);
	//printf("\tv3ofs+v3siz=%d \r\n", ss1.var3.offsetof + ss1.var3.sizeof);

	printf("SomeClass:\r\n");
	//printf("\tv1ofs=%d \r\n", SomeClass.var1.offsetof); // <- why not !@#?
	printf("\tsizeof=%d \r\n", sc1.sizeof);
	printf("\tv1ofs=%d \r\n", sc1.var1.offsetof);
	printf("\tv3ofs=%d \r\n", sc1.var3.offsetof);
	printf("\tv3ofs+v3siz=%d \r\n", sc1.var3.offsetof + sc1.var3.sizeof);

	/*
	c[0] = 'A';
	c[1] = '\n';
	c[2] = '\0';

	asm {
		//mov	EAX,offsetof c;
		lea EDX,c;
		add	EDX,0;
		mov	EAX,[EDX];
		and EAX,0x000000FF;
		mov	[somevar],EAX;
	}
	printf("somevar=%d\r\n", somevar);
	printf("c.length=%d\r\n", c.length);
	printf("%.*s\r\n", c);
	printf("enum.prop=%d\r\n", FruitTypes.init);
	*/

	//sas1.els = "texas";
	sas1.els[0] = 'A';
	sas1.els2 = sas1.els[0..1];
	printf("els.length = %d\r\n", sas1.els.length);
	//printf("els2.length = %d\r\n", sas1.els2.length);
	for (int i = 0; i < sas1.ints.length; i++) {
		printf("%d = %d\r\n", i, sas1.ints[i]);
	}

	//sas1.els = null;
	//delete sas1.els;
	printf("els.length = %d\r\n", sas1.els.length);
	for (int i = 0; i < sas1.ints.length; i++) {
		printf("%d = %d\r\n", i, sas1.ints[i]);
	}

}

extern (C) {
void PrintDMessage() {
	const static char[] msg = "Inside D language\0";
	const static char[] title = "Title\0";
	MessageBoxA(null, msg, title, 0);
}
}

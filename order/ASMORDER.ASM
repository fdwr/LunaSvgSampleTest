;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Comb Ordering Routines DLL
; Dwayne Robinson
; FDwR@hotmail.com
; 2002-04-15
;
; OS: Window 95+
; Language: assembler
; Compiler: NASM .98
; Linker: ALINK
;
; Written by request of and for Brian, to compensate for Visual Basic's
; ability to make a fast new computer seem like it's yesterday's model.
; Only after all other possible optimizations have been made should something
; be ported to assembler. Either that, or when you have TONs of data to order.
;
; Contents: Two callable routines for ordering large arrays.
; Current progress: Complete as far as I'm concerned...
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; History/Fixes:
;
; Seemingly infinite loop:
;   It wasn't actually an infinite loop after all. I was just too impatient
;   to let it finish. It only happens when the number of items is HUGE,
;   like 1 million or so. It occurs because a rare straggler somehow cheats
;   the first pass and causes the normally fast comb ordering to degrade
;   into the much slower bubble ordering. So now when there are one or two
;   such miscreants, I simply take another pass to put them in their place.
;
; Visual Basic singles were not working:
;   FPU flag bits are in a different order than the CPU flags, so moving
;   them to ax (fnstsw) and using JG just doesn't work. Instead, you must
;   TEST the bits and use JNZ/JZ. Also, I was using FCOM instead of FCOMP,
;   so after comparing only eight entries, VB would report the error
;   message "expression too complex". Huh? The true error was actually FPU
;   stack overflow.
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Function Parameters:
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; CombOrder (ArrayPtr, ArraySize, CmpCallback, EscCallback)
; - for ordering a single array of a single type
;
; array ptr
;   Pointer to first element of array. It only accepts 32bit data, meaning
;   the ordering routine can't work with byte or short arrays; but this
;   limitation should be acceptable considering longs, singles, and string
;   ptrs are generally types that need to be ordered anyway. The exact type
;   depends on what the comparison callback compares.
;
; array size
;   Number of elements, not byte size. Pass the actual number of elements
;   in the array, not UBOUND (which returns one less than the actual size).
;
; comparison callback
;   For versatility, the ordering routines do not any comparisons
;   themselves. Instead, they use the reply of a called function to
;   determine whether or not to swap values. The callback is provided two
;   parameters to compare, which it must then return true if they should be
;   swapped, false if they need not be.
;
;   Some common callbacks are provided local to the DLL, so that you need
;   not define your own in a high level language (which would counteract
;   the advantage of this being written in assembler). These internal
;   callbacks are faster because they can simply use the registers
;   (esi & edi) rather than setting up the whole stack frame just for the
;   sake of a mere two variables.
;
; escape callback
;   Since the ordering routine does NOT return to your own code until done,
;   this callback allows to check whether the user wants to abort the
;   ordering and gives an opportunity to update a progress meter. To abort,
;   it should return TRUE, otherwise the order continues. This routine is
;   only called only once each complete pass. It has no parameters.
;
;   Pass NULL if you do not want an escape callback.
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; CombOrderX (TotalArrays, NumCompareArrays, ArraySize, EscCallback,
;                 ArrayPtr1, ArrayType1, ArrayPtr2, ArrayType2...)
; - for ordering multiple parallel arrays of different types, with optional
;   subordering
;
; total arrays
;   The total number of arrays you are passing to it. This routine CAN accept
;   a variable number of parameters, so it is essential you tell it the
;   correct number of arrays being passed (otherwise the stack will not be
;   adjusted correctly before returning to the caller). Although the routine
;   can theoretically accept any number of arrays being passed to it (1-100),
;   many so called "high level" languages can not. So you will need to
;   retardly add another function definition for each number of arrays you
;   want to pass. For example, define one for passing two arrays, another for
;   passing three arrays, another for...
;
;   Needless to say, <=0 is invalid. DO NOT pass a negative count or else the
;   routine will not know how many variables to free from the stack.
;
; number of compare arrays
;   The number of arrays from the total that are used in the comparisons.
;   You might pass 4 arrays to be ordered, but only want to use 2 of those
;   for the comparison. For example, you want to arrange an episode listing
;   first by series names, then episode number. The other two attributes
;   (title & date) while important, will not be used in the comparison. They
;   will however be moved in parallel along with the other entries.
;
;   The order of importance (ordering/subordering) depends on the order the
;   arrays passed. If you first pass the epsiode number, then show name, it
;   will order first by episode, then suborder by name (which makes no sense).
;   To order by show, then episode number, just reverse them. The remaining
;   arrays are the least important (unused for comparison).
;
;   Needless to say, <=0 is invalid. At least one of the arrays must be used
;   for comparison, and it must be the first array passed.
;
; array size
;   Same as above. Total number of elements in array (UBOUND+1).
;
; escape callback
;   Same as above. Pass NULL if you do not want an escape callback.
;
; first array ptr
;   Same as above. The first of many arrays passed.
;
; first array type / comparison callback
;   Same as above. Specifies the type of data in the array.
;
; second array ptr
;   This array and every one afterwards is optional.
; 
; first array type / comparison callback
;   The type MUST be specified for each additional array passed, even if not
;   used for comparison.
;
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Visual Basic function definitions:
;
; Declare Sub CombOrder Lib "asmorder" _
;  (ByRef ArrayPtr As Any, _
;    ByVal ArraySize As Long, _
;    ByVal CmpCallback As Long, _
;    ByVal EscCallback As Long)
;
; Declare Sub CombOrderX Lib "asmorder" _
;  (ByVal TotalArrays As Long, _
;   ByVal CompareArrays As Long, _
;   ByVal ArraySize As Long, _
;   ByVal EscCallback As Long, _
;   ByRef Array1Ptr As Any, _
;   ByVal Array1Type As Long, _
;   ByRef Array2Ptr As Any, _
;   ByVal Array2Type As Long, _
;   ... )
;
; Public Function CmpCallbackString _
;  (ByRef Parm1 As String, _
;   ByRef Parm2 As String)
;
; Public Function CmpCallbackLong _
;  (ByVal Parm1 As Long, _
;   ByVal Parm2 As Long)
;
; Note that because VB is bad at finding DLLs, you must either:
; -Start it from the project (NOT open VB and then simply open the project) so
;  that the current directory points correctly. In other words, double click
;  on the VBP file.
; -Include the full path in the Lib statement.
; -Compile the program and run that.
; -Copy the DLL to WINDOWS\SYSTEM (bad choice).
;
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Calling from Visual Basic:
;
; 'A=ascending D=descending
; 'S=signed    U=unsigned
; Public Const CmpVoid     As Long = 0  '<- does nothing (for completeness ;)
; Public Const CmpReserved As Long = 1  '<- might use for variants, might not
; Public Const CmpLongSA   As Long = 2  '<- 32bit signed integers
; Public Const CmpLongSD   As Long = 3
; Public Const CmpLongUA   As Long = 4  '<- 32bit unsigned integers
; Public Const CmpLongUD   As Long = 5
; Public Const CmpSngA     As Long = 6  '<- floating point singles
; Public Const CmpSngD     As Long = 7
; Public Const CmpStrAA    As Long = 8  '<- ASCII null terminated C strings
; Public Const CmpStrAD    As Long = 9
; Public Const CmpStrWA    As Long = 10 '<- Widebyte Unicode C strings
; Public Const CmpStrWD    As Long = 11
; Public Const CmpStrBA    As Long = 12 '<- BSTR Visual Basic 4+ strings
; Public Const CmpStrBD    As Long = 13
;
; Const MaxShows As Long = 500 'array size
; Dim ShowNames(MaxShows-1) As String
; Dim ShowTitles(MaxShows-1) As String
; Dim ShowEps(MaxShows-1) As Long
; Dim ShowDates(MaxShows-1) As Date
;
; 'populate arrays with data from somewhere
; '...
;
; CombOrder ShowTitles(), MaxShows, CmpStrBA, 0
; CombOrder ShowTitles(), MaxShows, AddressOf(MyOwnCmp), 0
;
; CombOrderX 4,2,MaxShows, AddressOf(EscCallback), _
;   ByVal VarPtr(ShowNames(0)),CmpStrBA,  ShowEpNums(0),CmpLongSA, _
;   ByVal VarPtr(ShowTitles(0)),CmpStrBA, ShowDates(0),CmpSngA
;
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Limitations:
;
; 32bit array data only
;   It does not matter what type of 32 bit data it is, just as long as it
;   each entry in the array is 32bit (longs, singles, string ptrs). The
;   comparison callback can then take care of the type specifics. This
;   limitation restricts the algorithm from ordering byte arrays, but
;   ordering byte arrays really isn't one of the top requests.
;
; in memory order
;   The entire array must be located in memory. Actually, it is possible
;   if the comparison callback supported it, to also order disk records.
;   For example, if each entry was actually a file pointer. If you want
;   to do that though, don't even bother using this library because any
;   speed increases would be negligible. Also ensure you actually have
;   enough memory or else be prepared for major thrashing (ie. 10 million
;   longs on a 32MB machine).
;
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

[section data data]
[section code code]
[section bss bss]

global DllMain
global CombOrder
global CombOrderX

;%define debug
;%define profiling
%include "mywininc.asm"

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data

align 4,db 0
CmpFunc:    dd CmpVoid          ;callback to perform comparison
EscFunc:    dd NoEscCallback

CmpTblEntries equ 14
CmpTbl:     dd CmpVoid
            dd CmpVoid
            dd CmpLongSA
            dd CmpLongSD
            dd CmpLongUA
            dd CmpLongUD
            dd CmpSngA
            dd CmpSngD
            dd CmpStrAA
            dd CmpStrAD
            dd CmpStrWA
            dd CmpStrWD
            dd CmpStrBA
            dd CmpStrBD

%ifdef profiling
Swaps:      dd 0                ;number of swaps
Comps:      dd 0                ;number of comparisons
%endif
Swapped:    dd 0                ;flag that values have been swapped
ArrayCount: dd 0
CmpCount:   dd 0
SecondPass: dd 0

;section code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; ORDERING ROUTINES
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Doesn't do much, but what it does do is important for any program that
; calls this DLL. It will start fine the first time, but any attempts to
; start the same program later causes Windows to claim it is an invalid EXE
; format (which is totally ludicrous!?). So when the linker gives a warning
; about no entry point, take it seriously.

DllMain:
    ;api MessageBox, 0, Author, ProgTitle, 0
    mov eax,TRUE
    ret 12

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword array ptr,
;  dword array size,
;  dword comparison callback,
;  dword escape callback)
; (nothing)
CombOrder:
    debugmsg "dll stack=%x",esp

    paramsrel 16, .ArrayPtr, .ArraySize, .CmpFunc, .EscFunc
    push ebx,esi,edi            ;save these so VB doesn't get mad

    debugmsg "ArrayPtr=%x ArraySize=%d",[esp+.ArrayPtr+4],[esp+.ArraySize]

    mov eax,[esp+.CmpFunc]
    cmp eax,CmpTblEntries
    jae .ValidCmp
    mov eax,[CmpTbl+eax*4]      ;get local comparison callback from table
.ValidCmp:
    mov [CmpFunc],eax
    debugmsg "cmp func=%x",eax

    mov edx,[esp+.EscFunc]
    test edx,edx
    jnz .ValidEsc
    mov edx,NoEscCallback
.ValidEsc:
    debugmsg "esc func=%x",edx
    mov [EscFunc],edx

   %ifdef profiling
    xor eax,eax
    mov [Comps],eax             ;zero both the comparison and swap count
    mov [Swaps],eax
   %endif

    fninit                      ;for the floating point values
    cld                         ;likely unnecessary in Windows
    mov dword [SecondPass],FALSE


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; TOP OF ORDERING LOOP
    mov ebx,[esp+.ArraySize]    ;get initial gap entire array
.NextGap:
    ; calculate gap (x / 1.333_ == x * 3 / 4)
    lea ebx,[ebx+ebx*2]         ;*3
    shr ebx,2                   ;/4
    jnz .ValidGap
    inc ebx                     ;[ebx=0] must not have gap of zero
    cmp [SecondPass],ebx
    mov [SecondPass],ebx
    jb .UseGap
    mov ebx,[esp+.ArraySize]    ;get initial gap entire array
    lea ebx,[ebx+ebx*2]         ;*3
    shr ebx,2                   ;/4
  .ValidGap:
    cmp ebx,10                  ;if gap is 9 or 10, force to 11, since it
    ja .UseGap                  ;supposedly eliminates bubbles more quickly
    cmp ebx,9
    jb .UseGap
    mov ebx,11
  .UseGap:

    ; set element comparison pointers
    mov esi,[esp+.ArrayPtr]     ;start at front of array
    lea edi,[esi+ebx*4]         ;element to compare with = base + gap
    ;debugmsg "array ptrs=%x %x",esi,edi

    ; determine count of elements to compare
    mov ecx,[esp+.ArraySize]
    mov dword [Swapped],FALSE   ;initially assume everything is in order
    sub ecx,ebx                 ;array size - gap
    jbe .InvalidCount
    push ecx
    debugmsg "count=%d gap=%d",ecx,ebx
.NextComp:

    push esi
    push edi
    call [CmpFunc]              ;determine if values should be swapped
    test eax,eax                ;check if positive
    jle .NoSwap                 ;no swap since callback returned false or negative

%ifdef debug
    cmp ebx,1
    ja .NoShowSwap
    debugmsg "swapping %d with %d (%X,%X)",[esi],[edi],esi,edi
.NoShowSwap:
%endif
    mov eax,[esi]
    xchg [edi],eax              ;swap values/ptrs
    mov [Swapped],esi           ;[esi>=TRUE] a swap occurred (so continue loop)
    mov [esi],eax
   %ifdef profiling
    inc dword [Swaps]
   %endif

.NoSwap:
   %ifdef profiling
    inc dword [Comps]
   %endif

    add esi,byte 4              ;next source element
    add edi,byte 4              ;next comparison element
    dec dword [esp]             ;one less array element
    jg .NextComp                ;loop while counter > 0
    pop ecx                     ;discard counter

.InvalidCount:
    call [EscFunc]              ;check for user abort
    test eax,eax
    jnz .Abort                  ;abort function returned true (nonzero)

    cmp ebx,1
    ja near .NextGap            ;keeping looping while gap > 1
    cmp dword [Swapped],ebx     ;[ebx<=TRUE]
    jae near .NextGap           ;keep looping while any values were swapped

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; END OF LOOP
.Abort:
    pop ebx,esi,edi             ;restore these so VB doesn't get mad and crash
    debugmsg "dll stack=%x",esp
   %ifdef profiling
    debugmsg "comps=%d swaps=%d",[Comps],[Swaps]
   %endif
    ret 16


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CombOrderX:
    debugmsg "CombOrderX: entering"

    paramsrel 16, .TotalArrays, .CmpArrays, .ArraySize, .EscFunc, .ArrayPtr, .ArrayType
    push ebx,esi,edi            ;save these so VB doesn't get mad

    debugmsg "ArrayPtr=%x ArraySize=%d",[esp+.ArrayPtr+4],[esp+.ArraySize]
    debugmsg "TotalArrays=%d CmpArrays=%d",[esp+.TotalArrays+4],[esp+.CmpArrays]

    ; check total arrays and number to compare (sanity check)
    mov ecx,[esp+.TotalArrays]
    test ecx,ecx
    jle near .Abort             ;!! total arrays <= 0
    cmp [esp+.CmpArrays],ecx
    ja  near .Abort             ;!! cmp count > total arrays

    ; replace all instances of array type with appropriate callback
    shl ecx,3                   ;*8 for each array ptr|array type pair
.NextCmpPtr:
    mov eax,[esp+ecx+.ArrayType-8] ;get type of array
    cmp eax,CmpTblEntries
    jae .ValidCmp
    mov eax,[CmpTbl+eax*4]      ;get local comparison callback from table
    mov [esp+ecx+.ArrayType-8],eax ;set callback
.ValidCmp:
    sub ecx,byte 8
    jg .NextCmpPtr

    ; set escape callback
    mov edx,[esp+.EscFunc]
    test edx,edx
    jnz .ValidEsc
    mov edx,NoEscCallback
.ValidEsc:
    mov [EscFunc],edx

   %ifdef profiling
    xor eax,eax
    mov [Comps],eax             ;zero both the comparison and swap count
    mov [Swaps],eax
   %endif

    fninit                      ;for the floating point values
    cld                         ;likely unnecessary in Windows
    mov dword [SecondPass],FALSE


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; TOP OF ORDERING LOOP
    mov ebx,[esp+.ArraySize]    ;get initial gap entire array
.NextGap:
    ; calculate gap (x / 1.333_ == x * 3 / 4)
    lea ebx,[ebx+ebx*2]         ;*3
    shr ebx,2                   ;/4
    jnz .ValidGap
    inc ebx                     ;[ebx=0] must not have gap of zero
    cmp [SecondPass],ebx
    mov [SecondPass],ebx
    jb .UseGap
    mov ebx,[esp+.ArraySize]    ;get initial gap entire array
    lea ebx,[ebx+ebx*2]         ;*3
    shr ebx,2                   ;/4
  .ValidGap:
    cmp ebx,10                  ;if gap is 9 or 10, force to 11, since it
    ja .UseGap                  ;supposedly eliminates bubbles more quickly
    cmp ebx,9
    jb .UseGap
    mov ebx,11
  .UseGap:

    ; set element comparison pointers
    ; determine count of elements to compare
    xor esi,esi                 ;start at front of array
    mov ecx,[esp+.ArraySize]
    mov dword [Swapped],esi     ;[esi=FALSE] initially assume everything is in order
    sub ecx,ebx                 ;array size - gap
    jbe near .InvalidCount
    mov [ArrayCount],ecx
    debugmsg "count=%d gap=%d",ecx,ebx
.NextComp:

    ; compare first array's entries, then suborder if necessarry
    mov ecx,[esp+.CmpArrays]    ;get number of arrays to use for comparison
    lea edx,[esp+.ArrayPtr]     ;set function/array list ptr to base of passed arrays
    mov [CmpCount],ecx          ;set subcount
   %ifdef profiling
    inc dword [Comps]
   %endif

.NextArray:
    mov eax,[edx]               ;get array base ptr
    push esi,edx                ;save base ptr & current array
    add esi,eax                 ;array ptr + entry offset
    lea edi,[esi+ebx*4]         ;element to compare with = base + gap
    push esi,edi
    call [edx+4]                ;callback determines if values should be swapped
    test eax,eax                ;check if positive
    pop esi,edx                 ;restore base ptr & current array
    js .NoSwap                  ;no swaps since callback returned negative
    jg .Swap
    add edx,byte 8              ;advance to next array for suborder
    dec dword [CmpCount]        ;one less array to compare
    jg .NextArray
    jmp short .NoSwap

    ; swap all parallel entries
.Swap:
    mov ecx,[esp+.TotalArrays]
    lea edi,[esi+ebx*4]         ;element to compare with = base + gap
    mov dword [Swapped],ecx     ;[ecx>=TRUE] a swap occurred (so continue loop)
    shl ecx,3                   ;*8 for each array ptr|array type pair
.NextSwap:
    mov edx,[esp+ecx+.ArrayPtr-8] ;get ptr to array
    ;debugmsg "swapping %d with %d (%X,%X) +%X",[esi+edx],[edi+edx],esi,edi,edx
    mov eax,[esi+edx]           ;get first value/ptr
    xchg [edi+edx],eax          ;swap values/ptrs
    sub ecx,byte 8              ;one less array
    mov [esi+edx],eax           ;set value/ptr
    jg .NextSwap
.NoSwap:

    add esi,byte 4              ;next source element
    dec dword [ArrayCount]      ;one less array element
    jg .NextComp                ;loop while counter > 0

.InvalidCount:
    call [EscFunc]              ;check for user abort
    test eax,eax
    jnz .Abort                  ;abort function returned true (nonzero)

    cmp ebx,1
    ja near .NextGap            ;keeping looping while gap > 1
    cmp dword [Swapped],ebx     ;[ebx<=TRUE]
    jae near .NextGap           ;keep looping while any values were swapped

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; END OF LOOP
.Abort:
    debugmsg "CombOrderX: exiting"
    pop ebx,esi,edi             ;restore these so VB doesn't get mad and crash
    pop edx                     ;get return address
    pop eax                     ;get total arrays passed
    lea esp,[esp+12+eax*8]      ;adjust stack, *8 for each array ptr|array type pair
   %ifdef profiling
    debugmsg "comps=%d swaps=%d",[Comps],[Swaps]
   %endif
    jmp edx
    ;ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%ifdef profiling
GetProfilingInfo:
    params .Comps, .Swaps
    mov ecx,[esp+.Comps]        ;get ptr to variable (passed ByRef)
    mov edx,[esp+.Swaps]
    mov eax,[Comps]
    mov [ecx],eax
    mov eax,[Swaps]
    mov [edx],eax
    ret 8
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Since assembly isn't the easiest to read, here are two other examples in
; more familiar languages.

%if 0
DIM I AS LONG, J AS LONG, Temp AS LONG
CONST Shrink = 1.333333 '1.3
DIM Gap AS LONG
DIM Swapped AS INTEGER
Gap = TestSize
DO
    Gap = INT(Gap / Shrink)
    IF Gap <= 1 THEN Gap = 1
    Swapped = False
    FOR J = 0 TO TestSize - Gap - 1
        I = J + Gap
        IF Test(J) > Test(I) THEN
            Temp = Test(J)
            Test(J) = Test(I)
            Test(I) = Temp
            Swapped = True
        END IF
    NEXT J
LOOP WHILE Swapped OR Gap > 1

/**
 * A comb sort 11 sort demonstration algorithm
 * Idea from Byte April 1991 by Richard Box and Stephen Lacey
 * Michele Estebon (mestebon@vt.edu) brought this to my attention.
 * 
 * SortAlgorithm.java, Thu Oct 27 10:32:35 1994
 *
 * @author Jason Harrison@cs.ubc.ca
 * @version 	1.0, 20 Nov 1996
 *
 */
class CombSort11Algorithm extends SortAlgorithm {
    final float SHRINKFACTOR = (float)1.3;

    void sort(int a[]) throws Exception {
        boolean flipped = false;
        int gap, top;
        int i, j;

        gap = a.length;
        do {
            gap = (int) ((float) gap / SHRINKFACTOR);
            switch (gap) {
            case 0: /* the smallest gap is 1 - bubble sort */
                gap = 1;
                break;
            case 9: /* this is what makes this Combsort11 */
            case 10: 
                gap = 11;
                break;
            default: break;
            }
            flipped = false;
            top = a.length - gap;
            for (i = 0; i < top; i++) {
                if (stopRequested) {
                    return;
                }

                j = i + gap;
                if (a[i] > a[j]) {
                    int T = a[i];
                    a[i] = a[j];
                    a[j] = T;
                    flipped = true;
                }
                pause(i,j);
            }
        } while (flipped || (gap > 1));
        /* like the bubble and shell sorts we check for a clean pass */
    }
}
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; DEFAULT INTERNAL COMPARISON CALLBACKS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword source, dest, esi, edi)
; (swap TRUE/FALSE)
align 16
CmpLongSA:
    debugmsg "comparing %d with %d (%X,%X)",[esi],[edi],esi,edi
    mov edx,[esi]               ;get value from base
    cmp edx,[edi]               ;compare with second value
    jg .Swap
    je .Equal
.NoSwap:
    mov eax,-1
    ret 8
.Swap:
    mov eax,TRUE
    ret 8
.Equal:
    xor eax,eax
    ret 8

align 16
CmpLongSD:
    ;debugmsg "comparing %d with %d (%X,%X)",[esi],[edi],esi,edi
    mov edx,[esi]               ;get value from base
    cmp edx,[edi]               ;compare with second value
    jl CmpLongSA.Swap
    jg CmpLongSA.NoSwap
    xor eax,eax
    ret 8

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CmpVoid equ CmpLongSA.NoSwap

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
align 16
CmpLongUA:
    debugmsg "comparing %d with %d (%X,%X)",[esi],[edi],esi,edi
    mov edx,[esi]               ;get value from base
    cmp edx,[edi]               ;compare with second value
    ja CmpLongSA.Swap
    jb CmpLongSA.NoSwap
    xor eax,eax
    ret 8

align 16
CmpLongUD:
    debugmsg "comparing %d with %d (%X,%X)",[esi],[edi],esi,edi
    mov edx,[esi]               ;get value from base
    cmp edx,[edi]               ;compare with second value
    jb CmpLongSA.Swap
    ja CmpLongSA.NoSwap
    xor eax,eax
    ret 8

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
align 16
CmpSngA:
    debugmsg "comparing float %f with %f (%X,%X)",[esi],[edi],esi,edi
    fld dword [esi]             ;load first value into FPU
    fcomp dword [edi]           ;compare with second value
    fnstsw ax                   ;get FPU flags
    test ah,45h                 ;test FPU flags
    jz .Swap
    xor eax,eax
    ret 8
.Swap:
    mov eax,TRUE
    ret 8

align 16
CmpSngD:
    debugmsg "comparing float %f with %f (%X,%X)",[esi],[edi],esi,edi
    fld dword [esi]             ;load first value into FPU
    fcomp dword [edi]           ;compare with second value
    fnstsw ax                   ;get FPU flags
    test ah,01h                 ;test FPU flags
    jnz CmpSngA.Swap
    xor eax,eax
    ret 8

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Compare ASCII strings, null terminated
align 16
CmpStrAA:
    debugmsg "comparing %s with %s (%X,%X)",[esi],[edi],esi,edi
    ;cld                         ;shouldn't be necessary, but in case
    xor eax,eax                 ;set default return value to equal
    mov esi,[esi]               ;get ptr to first string
    mov edi,[edi]               ;and second string
    pop edx                     ;pop return address
.Next:
    cmp [esi],al                ;check for null in first string
    je .Stop                    ;stop if string ended
    cmpsb                       ;compare next character of each string
    je .Next
    jb .NoSwap
.Swap:
    pop edi                     ;restore ptrs for caller
    pop esi
    ;mov eax,TRUE               ;first > second, so return positive
    inc eax
    jmp edx                     ;return to caller
.Stop:
    cmp [edi],al                ;check for null in second string
    je .Equal                   ;they are equal if both end
.NoSwap:
    ;mov eax,-1                 ;first < second, so return negative (no swap)
    dec eax
.Equal: ;(eax=0)
    pop edi                     ;restore ptrs for caller
    pop esi
    jmp edx                     ;return to caller

align 16
CmpStrAD:
    debugmsg "comparing %s with %s (%X,%X)",[esi],[edi],esi,edi
    ;cld                         ;shouldn't be necessary, but in case
    xor eax,eax                 ;set default return value to equal
    mov esi,[esi]               ;get ptr to first string
    mov edi,[edi]               ;and second string
    pop edx                     ;pop return address
.Next:
    cmp [esi],al                ;check for null in first string
    je .Stop                    ;stop if string ended
    cmpsb                       ;compare next character of each string
    je .Next
    jb .Swap
.NoSwap:
    pop edi                     ;restore ptrs for caller
    pop esi
    ;mov eax,-1                 ;first > second, so return negative (no swap)
    dec eax
    jmp edx                     ;return to caller
.Stop:
    cmp [edi],al                ;check for null in second string
    je .Equal                   ;they are equal if both end
.Swap:
    ;mov eax,TRUE               ;first < second, so return positive
    inc eax
.Equal: ;(eax=0)
    pop edi                     ;restore ptrs for caller
    pop esi
    jmp edx                     ;return to caller

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Compare Unicode (widebyte) strings, null terminated
align 16
CmpStrWA:
    ;debugmsg "comparing %s with %s (%X,%X)",[esi],[edi],esi,edi
    ;cld                         ;shouldn't be necessary, but in case
    xor eax,eax                 ;set default return value to equal
    mov esi,[esi]               ;get ptr to first string
    mov edi,[edi]               ;and second string
    pop edx                     ;pop return address
.Next:
    cmp [esi],ax                ;check for null in first string
    je .Stop                    ;stop if string ended
    cmpsw                       ;compare next character of each string
    je .Next
    jb .NoSwap
.Swap:
    pop edi                     ;restore ptrs for caller
    pop esi
    ;mov eax,TRUE               ;first > second, so return positive
    inc eax
    jmp edx                     ;return to caller
.Stop:
    cmp [edi],ax                ;check for null in second string
    je .Equal                   ;they are equal if both end
.NoSwap:
    ;mov eax,-1                 ;first < second, so return negative (no swap)
    dec eax
.Equal: ;(eax=0)
    pop edi                     ;restore ptrs for caller
    pop esi
    jmp edx                     ;return to caller

align 16
CmpStrWD:
    ;debugmsg "comparing %s with %s (%X,%X)",[esi],[edi],esi,edi
    ;cld                         ;shouldn't be necessary, but in case
    xor eax,eax                 ;set default return value to equal
    mov esi,[esi]               ;get ptr to first string
    mov edi,[edi]               ;and second string
    pop edx                     ;pop return address
.Next:
    cmp [esi],ax                ;check for null in first string
    je .Stop                    ;stop if string ended
    cmpsw                       ;compare next character of each string
    je .Next
    jb .Swap
.NoSwap:
    pop edi                     ;restore ptrs for caller
    pop esi
    ;mov eax,-1                 ;first > second, so return negative (no swap)
    dec eax
    jmp edx                     ;return to caller
.Stop:
    cmp [edi],ax                ;check for null in second string
    je .Equal                   ;they are equal if both end
.Swap:
    ;mov eax,TRUE               ;first < second, so return positive
    inc eax
.Equal: ;(eax=0)
    pop edi                     ;restore ptrs for caller
    pop esi
    jmp edx                     ;return to caller

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Compare BSTRs strings, used by OLE2.0 and Visual Basic
align 16
CmpStrBA:
    debugmsg "comparing %s with %s (%X,%X)",[esi],[edi],esi,edi
    ;cld                         ;shouldn't be necessary, but in case
    mov esi,[esi]               ;get ptr to first string
    mov edi,[edi]               ;and second string
    mov ecx,[esi-4]             ;get length of first
    mov edx,[edi-4]             ;and second string
    xor eax,eax                 ;default is equal (no swap)
    cmp ecx,edx
    je .NotLonger
    dec eax                     ;in case strings match, pick shorter one
    jb .NotLonger
    mov ecx,edx                 ;set length to shorter one
    mov eax,TRUE                ;in case strings match, pick longer one
.NotLonger:

    repe cmpsw
    pop edx                     ;pop return address
    pop edi                     ;restore ptrs for caller
    pop esi
    ja .Swap
    jb .NoSwap
.Ret:                           ;strings equal so use lengths
    jmp edx                     ;return to caller
.Swap:
    mov eax,TRUE                ;first > second, so return positive
    jmp edx                     ;return to caller
.NoSwap:
    mov eax,-1                  ;first < second, so return negative
    jmp edx                     ;return to caller

align 16
CmpStrBD:
    debugmsg "comparing %s with %s (%X,%X)",[esi],[edi],esi,edi
    ;cld                         ;shouldn't be necessary, but in case
    mov esi,[esi]               ;get ptr to first string
    mov edi,[edi]               ;and second string
    mov edx,[esi-4]             ;get length of first
    mov ecx,[edi-4]             ;and second string
    xor eax,eax                 ;default is no swap
    cmp ecx,edx
    je .NotLonger
    dec eax                     ;in case strings match, pick shorter one
    jb .NotLonger
    mov ecx,edx                 ;set length to shorter one
    mov eax,TRUE                ;in case strings match, pick longer one
.NotLonger:

    repe cmpsw
    pop edx                     ;pop return address
    pop edi                     ;restore ptrs for caller
    pop esi
    jb CmpStrBA.Swap
    ja CmpStrBA.NoSwap
.Ret:                           ;strings equal so use lengths
    jmp edx                     ;return to caller

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply returns false. This stub is used when the calling program passes a
; NULL escape callback to the ordering routine.
NoEscCallback:
    xor eax,eax
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Can't simply do this :(
; Had to create RC file
%if 0
section resource

; IMAGE_RESOURCE_DIRECTORY
dd 0    ;Characteristics
dd 0    ;TimeDateStamp
dw 0    ;MajorVersion
dw 0    ;MinorVersion
dw 0    ;NumberOfNamedEntries
dw 1    ;NumberOfIdEntries

; IMAGE_RESOURCE_DIRECTORY_ENTRY
dd RT_VERSION   ;Name
dd VersionEntry ;OffsetToData

VersionEntry:
; IMAGE_RESOURCE_DATA_ENTRY
dd VersionData                  ;OffsetToData
dd EndVersionData-VersionData   ;Size
dd 04090000h                    ;CodePage
dd 0                            ;Reserved

VersionData:
dw EndVersionData-$             ;wLength (length of whole structure)
dw 0                            ;wValueLength (no VS_FIXEDFILEINFO)
dw 1                            ;bText (version contains text not binary)
db "VS_VERSION_INFO",0          ;WCHAR szKey[];
db "",0                         ;No VS_FIXEDFILEINFO Value

;Begin children
db "StringFileInfo",0
db "04090000",0
db "CompanyName",0,"PeekinSoft",0
db "FileDescription",0,"Comb Ordering Routine",0
db "FileVersion",0,".001",0
db "OriginalFilename",0,"asmorder.dll",0
db "Copyright",0,"Dwayne Robinson",0
EndVersionData:
%endif

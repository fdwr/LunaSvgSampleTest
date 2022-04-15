; MACROS32.ASM - Common 32bit routines
; Dwayne Robinson
; 2004-12-21
; Intended for NASM compiler.
;
; 2005-04-07  localsundef: fixed size bug 
;             localsundef(1): added partial local pop (for block scope)
;=============================================================================

%ifndef macros32_inc
%define macros32_inc

; Define an assembly label as global.
; If a symbol is only declared using this macro, rather than csym,
; it is NOT meant to be called by C functions.
%macro gsym 1.nolist
    global %1
    %1:
%endmacro

; Define both the unadultered name and
; silly C underscore prepended version.
; If a symbol is defined with this macro, it is meant to be called
; by both C and assembler functions.
%macro csym 1.nolist
    global _%1
    global %1
    _%1:
    %1:
%endmacro

; Overload that allows data declaration immediately after name
%macro csym 2+.nolist
    global _%1
    global %1
    _%1:
    %1: %2
%endmacro

; A more helpful at for local structures that declares a label too
%imacro atl 1-2+.nolist
    times %{$strucname}%1-($-%$strucstart) db 0
    %1:
    %2
%endmacro

%define alignd times ($$-$) & ((4)-1) db 0
%define alignq times ($$-$) & ((8)-1) db 0


;=============================================================================
; Basic conditionals ('if' taken from Gaz's Win32 Programming with NASM)

%macro if 3
    %push if
    %if %0 = 3
        cmp %1, %3
        j%-2 near %$i
    %endif
%endmacro

%macro ifany 3-*
    %push if
    %if %0 = 3
        cmp %1, %3
        j%-2 near %$i
    %else
        %assign %$c 0
        %rep ((%0-1) / 3)
            cmp %1, %3
            j%2 near %$i%$c             ;at least one matched, and so jump to true condition.
            %rotate 3
        %endrep
        cmp %1, %3
        j%-2 near %$i                   ;last condition failed, and so jumpd to false condition.
    %$i%$c:
    %endif
%endmacro

%imacro ifall 3-*
    %push if
    %if %0 = 3
        cmp %1, %3
        j%-2 near %$i                   ;jump to negative condition (%- means invert the condition code)
    %else
        %rep (%0 / 3)
            cmp %1, %3
            j%-2 near %$i               ;jump to negative condition (%- means invert the condition code)
            %rotate 3
        %endrep
        ;else fall through to true condition
    %endif
%endmacro

%imacro else 0
    %ifctx if
        %repl else
        jmp near %$e
        %$i:
    %else
        %error "Expected 'if' or 'ifand' before 'else'"
    %endif
%endmacro

%imacro endif 0
    %ifctx if
        %$i:
        %pop
    %elifctx else
        %$e:
        %pop
    %else
        %error "Expected 'if' before 'endif'"
    %endif
%endmacro


;=============================================================================
; Pushes a single dword item, whether register, address, or string.
; It allocates a temporary string if necessary. 'void' is a special
; identifier to do nothing - useful for api calls which already
; have some of the parameters pushed.
%macro pushd 1
    %ifidni %1,void
    %elifstr %1
[section .string]
      ; alignb 4,0
      %%Text: dw %1,0
__SECT__
      push dword %%Text
    %else
      push dword %1
    %endif
%endmacro

; Saves multiple registers. Instead of pushing them left to right, it pushes
; them right to left so that they are in the same order as routines expect
; parameters.
; (prm1, prm2, prm3...)
%ifndef push
%macro push 2-*
%rep %0
  %rotate -1
  pushd %1
%endrep
%endmacro
%endif

; Restores multiple registers, first left to right, so it will undo
; a previous multipush.
; (prm1, prm2, prm3...)
%ifndef pop
%macro pop 2-*
    %rep %0
      pop %1
      %rotate 1
    %endrep
%endmacro
%endif

%macro callc 1-*
    %rep %0 -1
      %rotate -1
      pushd %1
    %endrep
    %rotate -1
    extern %1
    call %1
    lea esp,[esp+(%0-1)*4]  ;restore stack by # params * 4 bytes
    ;add esp,(%0-1)*4
%endmacro


;=============================================================================
; Used by 'locals' below
; Allocates stack space for variable and defines variable name as register base
; plus stack offset.
; - Unlike params, the size must always be given.
; - technically byte and word parameters could packed together, but for now
;   they are put in whole dwords.
; - Variables are allocated descending order, exactly how the stack grows.
;   So the first variable declared will have the highest address. This is
;   backwards from usual variable declaration in assembly (usually later static
;   vars have higher addresses), but is necessary since (1) this simple macro
;   has no clue how many variables to expect and (2) this order simplifies
;   allocating more variables later. 
; - You may get a compile error if a variable is zero size.
;
; Examples:
; <ebp relative>
;   locals ebp
;   local top,4
;   local left,4
;   local rect,16
; <ebp relative>
;   locals ebp
;   local top,4, push dword 3
;   local left,4, push dword 5
;   local rect,16, sub esp,byte 16
; <esp relative>
;   locals esp+locals_size
;   local top,4
;   local left,4
;   local rect,16
; <absolute - which makes no sense but is possible>
;   locals 0,
;   local top,4
;   local left,4
;
; Examples mixed with params:
;
%macro locals 1.nolist
    %ifdef locals_base
      %error "Locals called twice. Call localsundef first before calling again."
    %endif
    %ifidn %1,esp
      %error "You probably want: locals esp+locals_size"
    %endif
    %ifnum %1
      %define locals_base 0
      %assign locals_size %1
    %else
      %define locals_base %1
      %assign locals_size 0
    %endif
    %ifndef locals_count
      %assign locals_count 0
    %endif
    ;%rep 1
    ;(%0-1)/2
      ;%rotate -2
      ;local %1,%2
    ;%endrep
%endmacro

; Make this its own macro just because NASM isn't capable of doing:
; locals{locals_count}
; It leaves the silly braces in there :(
%macro localdef 2
    ;%error enter 1=%1 2=%2
    %define locals_%2 %1
    %assign locals_count locals_count+1 ;count another variable
    ;%error exit  1=%1 2=%2 locals_%2
%endmacro


%macro local 0-3+.nolist
    ;%error local 0=%0 1=%1 2=%2 3=%3<<
    %3
    %if %0 < 2
      %error "local: parameters must include both name and size."
    %endif
    %assign locals_size locals_size+%2  ;increase stack space
    %assign locals_size ((locals_size+3)/4)*4 ;align to dword
    %assign ..%1 - locals_size   ;force numeric evaluation now, important!
    %1_offset equ ..%1                  ;set name to stack offset
    %ifnum locals_base
      %1 equ %1_offset                ;set name to stack offset
    %else
      %define %1 locals_base + %1_offset;define name as reg + stack offset
      localdef %1,locals_count          ;keep track of name to undef later
    %endif
%endmacro

; Undefine the numbered variable.
; Make this its own macro just because NASM needs to resolve the macro
; into the name. Just using "undef param{param_count}" won't work because
; it leaves the braces in there.
%macro localundef 1
    ;%error enter: 1=%1 locals#=locals_%1
    ;%error enter: 1=%1 locals#=locals_{%1}
    %undef locals_%1
    ;%error exit:  1=%1 locals#=locals_%1
    ;%error .message
%endmacro

; todo:fix
%macro unlocals 0.nolist
    ;;%error calling unlocals
    %ifndef locals_count
      %error "unlocals: locals_count is not set. Define locals first with locals or params macros."
    %endif
    %rep locals_count
      ;;%error calling unlocals loop
      %assign locals_count locals_count-1
      ;%error count = locals_count
      localundef locals_count
    %endrep
    ;;%error calling unlocals after loop
    %undef locals_count
    %undef locals_size
    %undef locals_base
    %undef params_base

    ;;%error calling unlocals ready to return
%endmacro

; todo: consider deleting unless use found
; Allows you to undefine previous local variables, allowing basic scope
; blocking. Note that scope is ONLY valid between the def and undef. If
; you use calls or jumps outside the block, the stack will not be what
; you expect.
;%macro unlocals 1-*.nolist
;   %if %0 > locals_count
;     %error "unlocals(count): Can't undefine more variables than were defined."
;   %else
;      %rep %1
;        %assign locals_count locals_count-1
;        localundef locals_count
;      %endrep
;     %if locals_count > 0
;       %assign %%offset locals_count-1
;       localspop %%offset
;        ;%assign locals_size locals_count-1
;     %else
;       %assign locals_size 0
;     %endif
;   %endif
;    %rep %0-1 ;should this go here or above?
;      %rotate -1
;      %1
;    %endrep
;%endmacro

;=============================================================================
; Assigns routine parameter names to stack offsets, relative to the first
; parameter after the return address (usually esp+4). The names should all be
; preceded by periods if they are to be routine local.
; - Since the parameters are usually 32bit, they are assumed to be dwords if
;   no size is given.
; ( relative base,  a numeric constant or register base like esp+4 or ebp-12
;   name 1,
;   name 2,
;   ...)
;
; Examples:
; <esp relative, broken lines>
;   params esp+4, hwnd, msg
;   param wparam,4
;   param lparam
; <esp relative, single line>
;   params ebp+20, string,24, length,4
; <absolute, single line>
;   params 0, infoptr, rect,16
;
%ifndef params

%macro param 1-2.nolist
    %assign %1_offset params_size       ;force numeric evaluation now, important!
    ;todo:delete.%1@ equ .%@            ;set name to stack offset
    %ifnum params_base
      %1 equ %1_offset                  ;set name to stack offset
    %else
      localdef %1,locals_count          ;keep track of name to undef later
      %define %1 params_base+%1_offset  ;define name as reg + stack offset
    %endif
    %ifnum %2
      %assign params_size params_size+%2;next parameter
    %else
      %assign params_size params_size+4 ;assume dword (4 bytes)
    %endif
%endmacro

%macro params 1-*.nolist
    %ifdef params_base
      %error "Params called twice. Call localsundef first before calling again."
    %endif
    %ifndef locals_count
      %assign locals_count 0
    %endif
    %ifnum %1
      %define params_base 0
      %assign params_size %1
    %else
      %define params_base %1
      %assign params_size 0
    %endif
    %assign %%i %0-1
    %rotate 1                           ; skip base (esp/ebp/#)
    %rep %0-1
      %ifnum %2
        param %1,%2
        %assign %%i %%i-2
        %rotate 2
      %else
        param %1
        %assign %%i %%i-1
        %rotate 1
      %endif
      %if %%i <= 0
        %exitrep
      %endif
    %endrep
%endmacro

%endif ; params

%endif ; macros32_inc
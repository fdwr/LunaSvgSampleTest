section code

;------------------------------
; (edi=destination, ecx=byte count) (trashes eax, ecx, edx)
;
ZeroFill:
    push edi
    cld
    xor eax,eax
    mov edx,ecx
    shr ecx,2
    rep stosd                           ;32-bits at a time
    mov ecx,edx
    and ecx,3
    rep stosb                           ;8-bits residual
    pop edi
    ret

%macro MovDwordViaEax 2
    mov eax,%2
    mov %1,eax
%endmacro

%ifndef pushparam32 
%macro pushparam32 1
      %ifidni %1,void   ; todo: This seems dangerous - delete? Why was it added? esp may not be adjusted correctly later.
      %elifstr %1
[section string]
        ; alignb 4,0
        %%Text: db %1,0
__SECT__
        push dword %%Text
      %else
        push dword %1
      %endif
%endmacro
%endif

%ifndef pushparams32_right_to_left
%macro pushparams32_right_to_left 0-*
  %rep %0
      %rotate -1
      pushparam32 %1
  %endrep
%endmacro
%endif

%ifndef popparams32_right_to_left
%macro popparams32_right_to_left 0-*
  %assign %%counter 0
  %rep %0
      %rotate -1
      %assign %%counter %%counter+4
  %endrep
  add esp,byte %%counter
%endmacro
%endif

%define pushparams32_rtl pushparams32_right_to_left

; Push dword parameters, and call function.
%macro pushcall 1-2+
  pushparams32_right_to_left %2
  call %1
  popparams32_right_to_left %2
%endmacro

%define makeyxparam(y,x) (y)|((x)<<16)

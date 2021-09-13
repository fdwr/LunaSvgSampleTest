; IFSHLP.SYS   Long file support
; Startup code

.data
  _mask db '*',0

.code

detect_lfn proc private
  sub esp,sizeof callstruct
  mov [esp].callstruct._eax,714eh   ;Attempt Find First
  mov [esp].callstruct._ecx,0ffh
     ;CL = allowable masks (same as ax=4301h, bits 0,5 ignored)
     ;CH = required masks  (same as CL)
  mov ax,_8kbufferseg
  mov [esp].callstruct._ds,ax       ;DS:DX = search string
  mov [esp].callstruct._edx,0
  mov [esp].callstruct._es,ax       ;ES:DI = data buffer
  mov [esp].callstruct._edi,10h
  mov [esp].callstruct._esi,0h      ;SI = flag (0=64bit date   1=MS-DOS date)
  mov [esp].callstruct._ss,0     ;FIX : v2.11 Beta #3 : must clear stack
  mov [esp].callstruct._sp,0   
  mov [esp].callstruct._flg,1    ;FIX : v2.11 Beta #3 : set carry before call

  mov esi,offset _mask
  mov edi,_8kbuffer
  mov ecx,sizeof _mask
  rep movsb

  mov edi,esp
  mov ax,300h
  xor ecx,ecx
  mov bx,21h     ;INT 21h/ax=714eh
  int 31h
  jc failed

  test [esp].callstruct._flg,1
  jnz failed        ;Carry set?

  mov ax,wptr[esp].callstruct._eax    ;Win95 FindFile handle
  mov wptr[esp].callstruct._ebx,ax
  mov [esp].callstruct._eax,071a1h    ;Release handle

  mov ax,300h
  mov edi,esp
  mov bx,21h
  xor ecx,ecx
  int 31h
  jc failed

  test [esp].callstruct._flg,1
  jnz failed        ;Carry set?

success:            ;LFN support available
  add esp,sizeof callstruct
  mov _lfn,1
  ret

failed:             ;LFN support not available
  add esp,sizeof callstruct
  mov _lfn,0        
  ret
detect_lfn endp


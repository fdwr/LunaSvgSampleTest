;=============================================================================
; RENDER.ASM   Dwayne Robinson   2004-03-27
;=============================================================================
; Draws the force fields between points. Specifically, this is written for
; electric fields; however, since many forces decay by an inverse square, it
; could also be used for gravitation, light, and magnetic fields.
;
; Grr. It's only slightly faster than the C version, and that includes the
; optimization of removing the two multiplies. I will need to look at the
; compiler's disassembly to see what optimizations it is performing. The C
; routine does use statict global vars while the asm version accepts any,
; which may explain some speed loss.

; Particle attributes:
;   x,y - particle position in pixels
;   q - charge strength (signed) in arbitrary integral units (not Coulombs)
;   vx,vy - speed in horizontal/vertical pixels
;   m - mass in arbitrary integral units (not kilograms)

; Vars:
;   x - current column, scanning left to right
;   y - current row, scanning top to bottom
;   xd - x difference (current x - point x)
;   yd - y difference (current y - point y)
;   ds - distance squared (ds = r^2 = x^2 + y^2 = xds + yds)

; Particle vars:
;   yds - y difference squared, distance to particle on current row
;   xds - x difference squared, distance to particle on current column


struc EfofRenderPoint
.xds resd 1
.yds resd 1
endstruc

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; accepts:
;  (int particle list,
;   int number of particles,
;   ptr buffer pixels,
;   int buffer width,
;   int buffer height,
;   int buffer wrap)
; returns:
;   none (all general regs modified)
EfofRender:
    params ebp+8, .points,.numpoints, .pixels, .width,.height, .wrap
    
    push ebp
    mov ebp,esp
    mov eax,[.numpoints]
    test eax,eax
    jle near .End
    
	locals ebp
	local .y,4
	local .x,4
    lea eax,[eax*EfofRenderPoint_size+locals_size] ;*8 bytes for each point charge plus local x,y vars
    sub esp,eax                 ;allocate temp array to reduce multiplies

    ; for each row
    ;   calc row strength
    ;   calc initial column strength
    ;   for each col
    ;     zero charge total
    ;     for each point charge
    ;       distance = yds + xds
    ;       charge total += point charge / distance
    ;       adjust points strength for next col
    ;     end for
    ;   end for
    ; end for

    ; Simplifying the full formula for each pixel into a single division
    ;   and several subtracts and adds.
    ; e = kq / r^2                  <- discard useless constant k (1/4piE)
    ;   = q  / r^2                  <- calc hypotenuse
    ;   = q  / sqr(xd^2  + yd^2)^2  <- square and root cancel
    ;   = q  /    (xd^2  + yd^2)    <- simplify square into self multiply
    ;   = q  /    (xd*xd + yd*yd)   <- calc yd*yd only once per row
    ;   = q  /    (xd*xd + yds)     <- calc xd*xd at x=0, then simply add
    ;   = q  /    (xds   + yds)

    ; esp=point array temp info
    ; edi=buffer ptr
    ; ecx=accumulated charge total for pixel
    ; ebx=distance to point
    ; esi=current point attributes
    ; edx=current point number

    mov dword [.y],0
    mov edi,[.pixels]

.NextRow:
    ; precalc xds and yds for each particle for the entire row
    ; to reduce the number of multiplies in the innermost from 2 to 0
    mov esi,[.points]           ; back to first point's attributes
    mov ecx,[.numpoints]
    xor edx,edx
    mov ebx,[.y]
    mov dword [.x],edx
 .NextPointDs:
    ; calc xds from column 0 to point charge
    mov eax,[esi+PointCharge.x] ; xd = particle.x
    imul eax,eax                ; xds = xd*xd
    mov [esp+edx*8+EfofRenderPoint.xds],eax ; set xds for initial col (x=0)
    ; calc yds at current row
    mov eax,ebx
    sub eax,[esi+PointCharge.y] ; yd = y - particle.y
    imul eax,eax                ; yds = yd*yd
    mov [esp+edx*8+EfofRenderPoint.yds],eax ; set yds for current row
    ; next point
    inc edx
    add esi,byte PointCharge_size
    cmp ecx,edx
    jg .NextPointDs             ; loop while point < numpoints

.NextCol:
    mov esi,[.points]           ; back to first point's attributes
    xor ecx,ecx                 ; zero accumulated pixel e field
    xor edx,edx                 ; zero accumulated pixel e field

.NextPoint:
    ; calc distance squared from pixel to point charge
    mov eax,[.x]
    mov ebx,[esp+edx*8+EfofRenderPoint.xds]    ; get xds for current col
    sub eax,[esi+PointCharge.x] ; xd = x - particle.x
    lea eax,[eax*2+1]
    add eax,ebx                 ; xds += (xd*2)+1   (to avoid slow multiply)
    add ebx,[esp+edx*8+EfofRenderPoint.yds] ; ds = xds + yds
    mov [esp+edx*8+EfofRenderPoint.xds],eax ; set new xds for next col

    ; calc electric field (e = q / d^2)  (zero flag set if ebx=0)
    push edx                    ; save since dumb idiv trashes it
    mov eax,[esi+PointCharge.q]
    jz .OnPoint                 ; if ebx = 0
    cdq
    idiv ebx                    ; q / ds
.OnPoint:
    pop edx
    add ecx,eax                 ; etotal += epoint

    ; next point
    inc edx                     ; point++
    add esi,byte PointCharge_size
    cmp [.numpoints],edx
    jg .NextPoint               ; loop while point < numpoints
.EndPoint:

    ; clip charge value -128 to 127
    add ecx,128
    js .ChargeLess
    cmp ecx,255
    jbe .ChargeOk
.ChargeMore:
    mov ecx,255
    jmp short .ChargeOk
.ChargeLess:
    xor ecx,ecx
.ChargeOk:

    mov [edi],cl                ; write pixel byte
    mov eax,[.width]
    inc edi                     ; next pixel to the right
    inc dword [.x]
    cmp [.x],eax
    jl .NextCol                 ; loop while x < width
.EndCol:

    mov ecx,[.height]
    ;add edi,[.wrap]            ; pixel ptr += wrap
    inc dword [.y]              ; y++
    cmp [.y],ecx
    jl near .NextRow            ; loop while y < height
.EndRow:

.End:
    mov esp,ebp
    pop ebp
    ret 6*4

    unlocals


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; (ptr RGBQUAD pal[], int type)
; ()
EfofPaletteGen:
    params 4, .pal, .type
    mov eax,[esp+.type]
    mov edi,[esp+.pal]
    cmp eax,1
    je .Gray
    cmp eax,2
    je .Rainbow
    ;cmp eax,0
    jmp short .Electric

.Electric:
    mov eax,08080FFh
    mov ecx,128
.ElectricNext:
    mov [edi],eax
    sub eax,000001h
    add edi,byte 4
    dec ecx
    jg .ElectricNext
    mov ecx,128
    mov eax,0808080h
.ElectricNext2:
    mov [edi],eax
    add eax,0010000h
    add edi,byte 4
    dec ecx
    jg .ElectricNext2
    jmp .End

.Gray:
    ;xor eax,eax
    mov eax,0FFFFFFh
    mov ecx,128
.GrayNext:
    mov [edi],eax
    sub eax,010101h
    add edi,byte 4
    dec ecx
    jg .GrayNext
    mov ecx,128
.GrayNext2:
    mov [edi],eax
    add eax,010101h
    add edi,byte 4
    dec ecx
    jg .GrayNext2
    jmp .End

.Rainbow:
    mov ecx,255
.RainbowNext:
    mov [edi],ecx
    mov [edi+RGBQUAD.rgbRed],cl
    mov eax,ecx
    not eax
    mov [edi+RGBQUAD.rgbBlue],al
    ;fild
    ;fmul
    ;fsin   pal[count].rgbGreen=(unsigned char)(255*sin(count* 0.01227184630309));
    mov byte [edi+RGBQUAD.rgbGreen],128
    add edi,byte 4
    dec ecx
    jge .RainbowNext
    jmp .End

.End:
    ret 2*4

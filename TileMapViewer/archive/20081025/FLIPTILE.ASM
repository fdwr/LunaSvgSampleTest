;Tile flipping test

BITS 32                         ;flat addressing is great!
GLOBAL _WDOSXStart              ;great (free!) extender

    mov eax,[TileTableSize]
    mov ebx,eax
    imul ah                 ;get rows * columns
    and eax,127
    jz near .End            ;prevent division by zero
    mov ecx,eax
    mov eax,32768           ;size of tile table
    xor edx,edx             ;zero upper quotient
    idiv ecx                ;get tiletablesize / tilesize
    shl eax,16              ;set loop counter to top word
    mov ax,bx               ;set low word to rows and columns
    mov esi,TileTable
    cld
    test ebx,10000h
    jz .WordTiles

.ByteTiles:
    sub esp,ecx             ;reserve size of one tile on stack
    lea edx,[ecx-1]         ;set to tilesize - 1
    push esi                ;save tile pointer
.NextTileByte:
    lea edi,[esp+4]         ;destination of copy is stack
    mov esi,[esp]           ;get source in TileTable
    lea ecx,[edx+1]         ;get bytes per tile
    rep movsb               ;copy tile to stack

    mov edi,[esp]           ;get current tile ptr
    mov [esp],esi           ;save ptr to tile after current
    lea esi,[esp+4]         ;set source to stack
    mov bl,al               ;set rows
    mov cl,ah               ;set row increment to columns
.NextRowByte:
    mov bh,ah               ;reset columns
.NextColByte:
    movsb                   ;transfer tile table byte
    lea esi,[esi+ecx-1]     ;next row down
    dec bh                  ;one less column
    jnz .NextColByte
    sub esi,edx             ;back to top row
    dec bl                  ;one less row
    jnz .NextRowByte

    sub ebx,65536
    jns .NextTileByte
    add esp,byte 4
.End:
    ret

.WordTiles:
    shl ecx,1
    sub esp,ecx
    lea edx,[ecx-2]
    push esi                ;save tile pointer
.NextTileWord:
    lea edi,[esp+4]         ;destination of copy is stack
    mov esi,[esp]           ;get source in TileTable
    lea ecx,[edx+2]         ;get bytes per tile
    rep movsb               ;copy tile to stack

    mov edi,[esp]
    mov [esp],esi
    lea esi,[esp+4]
    mov bl,al               ;set rows
    mov cl,ah               ;set row increment to columns
.NextRowWord:
    mov bh,ah               ;reset columns
.NextColWord:
    movsw                   ;transfer tile table word
    lea esi,[esi+(ecx*2)-2] ;next row down
    dec bh                  ;one less column
    jnz .NextColWord
    sub esi,edx             ;back to top row
    dec bl                  ;one less row
    jnz .NextRowWord
    pop esi                 ;to next tile

    sub ebx,65536
    jns .NextTileWord
    ret

TileTableSize:  db 2,2,1,0

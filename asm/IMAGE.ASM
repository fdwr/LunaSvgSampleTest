;IMAGE.COM by FDwR, Dec 5,1998
;
;This simply displays a 256color 320x200 image onto the screen until the user
;presses a key. Nice for if you want to turn off your computer with a certain
;pic visible. Note that the image and palette are embedded directly into the
;com file for two simple reasons. One is that is that there is enough space
;to, so why add the complexity of file loading and all that? The other is that
;this way, you have a complete mini-package and do not need to mess around
;with any other separate image files. Believe it or not, it actually takes
;less space to store the code and all the image data than the equivalent pic
;as a Windows bitmap. The image input is a 8bit 320x200 linear bitmap of pure
;pixels (no header info), and the palette data is 256 colors, 3 bytes per rgb
;tuple, 64 shades.
;
;The -q option can be used to quietly quit (that's where the 'q' came from,
;but you probably guessed that). It would be for if you wanted it to simply
;display the image without the waiting for the user to press a key and then
;resetting the video mode back to text. If you want to restore your screen
;to text mode later, the simplest way would be to just run it again (this
;time without the '-q' switch so that it would reset the video mode).
;Who knows, maybe you would want to use this option in a batch or somthing.

BITS 16                 ;oh well, no flat addressing here
ORG 100h                ;256 byte offset for working with a com file

;-----------------------------------------------------------------------------
SECTION .text           ;the code only takes up a mere 77 bytes
                        ;it is the data below that takes up so much space
MainRoutine:
        ;mov ax,cs       ;get segment of code
        ;mov ds,ax       ;set data segment to code segment
        ;mov es,ax       ;set extra segment also

.SetVideoMode:
        mov ax,13h      ;mode 13h is 320x200:256
        int 10h         ;call video BIOS

.SetPalette:
        xor al,al       ;set first color to zero
        mov dx,3C8h     ;palette index port
        out dx,al       ;tell VGA adapter the color index to start setting
        inc dx          ;select the VGA color palette port
        mov si,Palette  ;set starting index in palette
        mov cx,256*3    ;set to write 256*3 rgb color values in palette
        cld             ;read memory forward
        rep outsb       ;port accepts consecutive bytes of color values

.BlitImage:
        mov si,Image    ;set source to image to draw
        les di,[ScreenSegment]  ;get destination (VGA screen)
        mov cx,64000/4  ;number of four pixels in a 320x200 image
;        cld             ;read memory forward
        rep movsd       ;transfer image to screen

.CheckCommandLine:
        cmp byte [80h],3
        jb .Wait
        cmp word [82h],"-q"
        je .End

.Wait:
        mov ah,0        ;function to get last or wait for next key press
        int 16h         ;call BIOS

.ResetScreen:
        mov ax,3h       ;normal text mode
        int 10h         ;call video BIOS

.DisplayText:
        mov dx,Description      ;set source of text to image description
        mov ah,9                ;function to print out string
        int 21h                 ;call DOS
.End:
        mov ax,4C00h    ;function to terminate self (die)
        int 21h         ;call DOS

;-----------------------------------------------------------------------------
SECTION .data           ;the data that uses 768+64000 bytes

ScreenSegment:
dw 0,0A000h

Palette:
incbin "image.pal",0,768        ;256 color, three bytes per tuple, 64 shades

Image:
incbin "image.lbm",0,64000      ;pure linear bitmap pixel data (no header)

Description:
incbin "imgtitle.txt",0,256     ;optional little text description of image
db '$'                  ;must be sure that text string has an end

' Brought to you by HELiX
' QBasic version 1998 by Andre V1ctor / BRAZIL
'
' Tha 2d bumper.. based on a French tutorial found somewhere in the net..
' The purpose of this document is to help u understand the basic idea
' It is not optimized but who cares anyway? :)

' WARNING!!! Instructions for 386 are used.
' Load QB.QLB... qb /l

DEFINT A-Z
'$DYNAMIC

DECLARE SUB AsmBump  ()
DECLARE SUB BasBump  ()
DECLARE SUB Cls32    () 
DECLARE SUB Flip32   ()
DECLARE SUB Pal      (c AS INTEGER, r AS INTEGER, g AS INTEGER, b AS INTEGER)
DECLARE SUB SetupPal ()
 
     DIM i AS INTEGER, cd AS INTEGER
    
     DIM SHARED vscr1(0 TO 31999) AS INTEGER    ' our virtual screens
     DIM SHARED vscr2(0 TO 31999) AS INTEGER

     DIM Cls32cd(0 TO 27) AS STRING * 1
     DIM Flip32cd(0 TO 35) AS STRING * 1
     DIM AsmBumpCd(0 TO 163) AS STRING * 1

     
     RESTORE Cls32                              ' Read machine-language procs
    FOR i = 0 TO 27
     READ cd
     Cls32cd(i) = CHR$(cd)
    NEXT i
    
     RESTORE Flip32
    FOR i = 0 TO 35
     READ cd
     Flip32cd(i) = CHR$(cd)
    NEXT i
    
     RESTORE AsmBump
    FOR i = 0 TO 163
     READ cd
     AsmBumpCd(i) = CHR$(cd)
    NEXT i


   PRINT "The HELiX 2D Bump Tut"
   PRINT
   PRINT "Based on some nice tutorial in French"
   PRINT "Quite slow.. why dont u optimize it..? :).."
   PRINT
   PRINT "Orpheas/HELiX"
   PRINT "Dec/96"
   PRINT
   PRINT "QBasic version 1998 by Andre V1ctor / BRAZIL"

   PRINT
   PRINT "Press any key..."
   WHILE INKEY$ = "": WEND
 
    
     SCREEN 13
 
     DEF SEG = VARSEG(vscr1(0))                 ' Load image
     BLOAD "remap.bsv", VARPTR(vscr1(0))

     SetupPal                                   ' Set the pallete
     AsmBump                                    ' do it.. :)
 
    
   SCREEN 0
   WIDTH 80

   PRINT "Thats all folks.."
   PRINT
   PRINT "If you still have any questions/comments/money/girls for me"
   PRINT "E-mail:helix@matrix.kapatel.gr"


':::::::::::::::::::::::::::::::::::::::::::::::::
Cls32:
DATA &H8b, &Hdc              : ' mov            bx, sp
DATA &H57, &H06              : ' push           di, es
DATA &H36, &H8b, &H5f, &H04  : ' mov            bx, ss:[bx + 04]
DATA &H8b, &H07              : ' mov            ax, ds:[bx]
DATA &H8e, &Hc0              : ' mov            es, ax
DATA &H33, &Hff              : ' xor            di, di
DATA &H66, &H33, &Hc0        : ' xor            eax, eax
DATA &Hb9, &H80, &H3e        : ' mov            cx, 16000
DATA &H66, &Hf3, &Hab        : ' rep            stosd
DATA &H07, &H5f              : ' pop            es, di
DATA &Hca, &H02, &H00        : ' retf           (2)

':::::::::::::::::::::::::::::::::::::::::::::::::
Flip32:
DATA &H8b, &Hdc              : ' mov            bx, sp
DATA &H57, &H56, &H06, &H1e  : ' push           di, si, es, ds
DATA &Hb8, &H00, &Ha0        : ' mov            ax, 0A000h
DATA &H8e, &Hc0              : ' mov            es, ax
DATA &H33, &Hff              : ' xor            di, di
DATA &H36, &H8b, &H5f, &H04  : ' mov            bx, ss:[bx + 04]
DATA &H8b, &H07              : ' mov            ax, ds:[bx]
DATA &H8e, &Hd8              : ' mov            ds, ax
DATA &H33, &Hf6              : ' xor            si, si
DATA &Hb9, &H80, &H3e        : ' mov            cx, 16000
DATA &H66, &Hf3, &Ha5        : ' rep            movsd
DATA &H1f, &H07, &H5e, &H5f  : ' pop            ds, es, si, di
DATA &Hca, &H02, &H00        : ' retf           (2)

':::::::::::::::::::::::::::::::::::::::::::::::::
AsmBump:
DATA &H55                     : ' push           bp
DATA &H89, &He5               : ' mov            bp, sp
DATA &H57                     : ' push           di
DATA &H56                     : ' push           si
DATA &H06                     : ' push           es
DATA &H1e                     : ' push           ds
DATA &H8b, &H5e, &H0a         : ' mov            bx, [bp + 10]
DATA &H8b, &H1f               : ' mov            bx, [bx]
DATA &H8e, &Hc3               : ' mov            es, bx
DATA &H8b, &H5e, &H08         : ' mov            bx, [bp + 08]
DATA &H8b, &H17               : ' mov            dx, [bx]
DATA &Hf7, &HdA               : ' neg            dx
DATA &H8b, &H5e, &H06         : ' mov            bx, [bp + 06]
DATA &H8b, &H3f               : ' mov            di, [bx]
DATA &Hf7, &Hdf               : ' neg            di
DATA &H8b, &H5e, &H0c         : ' mov            bx, [bp + 12]
DATA &H8b, &H1f               : ' mov            bx, [bx]
DATA &H8e, &Hdb               : ' mov            ds, bx
DATA &H8b, &HeA               : ' mov            bp, dx
DATA &Hbe, &H41, &H01         : ' mov            si, 321
DATA &Hb9, &Hc6, &H00         : ' mov            cx, 198
DATA &H47                     : ' inc            di
DATA &H83, &Hff, &H80         : ' cmp            di, -128
DATA &H7c, &H64               : ' jl             0195
DATA &H81, &Hff, &H80, &H00   : ' cmp            di, 128
DATA &H7f, &H5e               : ' jg             0195
DATA &H51                     : ' push           cx
DATA &H8b, &Hd5               : ' mov            dx, bp
DATA &Hb9, &H3e, &H01         : ' mov            cx, 318
DATA &H42                     : ' inc            dx
DATA &H83, &Hfa, &H80         : ' cmp            dx, -128
DATA &H7c, &H45               : ' jl             0188
DATA &H81, &Hfa, &H80, &H00   : ' cmp            dx, 128                  
DATA &H7f, &H3f               : ' jg             0188
DATA &H33, &Hdb               : ' xor            bx, bx                    
DATA &H8a, &H5c, &H01         : ' mov            bl, [si + 1]
DATA &H2a, &H5c, &Hff         : ' sub            bl, [si - 1]
DATA &H80, &Hdf, &H00         : ' sbb            bh, 00
DATA &H2b, &Hda               : ' sub            bx, dx
DATA &H7e, &H02               : ' jle            015a
DATA &Hf7, &Hdb               : ' neg            bx
DATA &H83, &Hc3, &H7f         : ' add            bx, 127
DATA &H7d, &H02               : ' jge            0161
DATA &H33, &Hdb               : ' xor            bx, bx
DATA &H8b, &Hc3               : ' mov            ax, bx
DATA &H33, &Hdb               : ' xor            bx, bx
DATA &H8a, &H9c, &H40, &H01   : ' mov            bl, [si + 320]
DATA &H2a, &H9c, &Hc0, &Hfe   : ' sub            bl, [si - 320]
DATA &H80, &Hdf, &H00         : ' sbb            bh, 00
DATA &H2b, &Hdf               : ' sub            bx, di
DATA &H7e, &H02               : ' jle            0176
DATA &Hf7, &Hdb               : ' neg            bx
DATA &H83, &Hc3, &H7f         : ' add            bx, 127
DATA &H7d, &H02               : ' jge            017d
DATA &H33, &Hdb               : ' xor            bx, bx
DATA &H01, &Hc3               : ' add            bx, ax
DATA &H81, &Hfb, &H80, &H00   : ' cmp            bx, 128
DATA &H7e, &H03               : ' jle            0188
DATA &H26, &H88, &H1c         : ' mov            es;[si], bl
DATA &H46                     : ' inc            si
DATA &H49                     : ' dec            cx
DATA &H75, &Hb1               : ' jnz            013d
DATA &H83, &Hc6, &H02         : ' add            si, 2
DATA &H59                     : ' pop            cx
DATA &H49                     : ' dec            cx
DATA &H75, &H98               : ' jnz            012b
DATA &Heb, &H07               : ' jmp            019c
DATA &H81, &Hc6, &H40, &H01   : ' add            si, 320
DATA &H49                     : ' dec            cx
DATA &H75, &H8f               : ' jnz            012b
DATA &H1f                     : ' pop            ds
DATA &H07                     : ' pop            es
DATA &H5e                     : ' pop            si
DATA &H5f                     : ' pop            di
DATA &H5d                     : ' pop            bp
DATA &Hca, &H08, &H00         : ' retf           (8)

REM $STATIC
':::::::::::::::::::::::::::::::::::::::::::::::::
SUB AsmBump
    
     SHARED AsmBumpCd() AS STRING * 1
     DIM lx   AS INTEGER
     DIM ly   AS INTEGER
     DIM l1   AS INTEGER
        
     lx = 160
     ly = 100
     l1 = 0
                
  DO
     l1 = l1 + 4
     lx = CINT(160 + (COS(l1 / 13) * 99))
     ly = CINT(100 + (SIN(l1 / 23) * 99))

     DEF SEG = VARSEG(AsmBumpCd(0))
     CALL absolute(VARSEG(vscr1(0)), VARSEG(vscr2(0)), lx, ly, VARPTR(AsmBumpCd(0)))
    
     Flip32
     Cls32

  LOOP UNTIL INKEY$ > ""

END SUB

':::::::::::::::::::::::::::::::::::::::::::::::::
SUB Cls32
' This clears the virtual screen 2

     SHARED Cls32cd() AS STRING * 1
    
     DEF SEG = VARSEG(Cls32cd(0))
     CALL absolute(VARSEG(vscr2(0)), VARPTR(Cls32cd(0)))
END SUB

':::::::::::::::::::::::::::::::::::::::::::::::::
SUB BasBump
' Now u guess what this one does..hehehe
    
  ' Now I shall explain the variables used
     DIM x    AS INTEGER                  ' These two are used in the
     DIM y    AS INTEGER                  '  main loop
     DIM vlx  AS INTEGER, vly AS INTEGER  ' The Light Vector (Origin 0,0)
     DIM lx   AS INTEGER                  ' This is a point representing the
     DIM ly   AS INTEGER                  '  position of the light source
     DIM Nx   AS INTEGER                  ' This will be used to store the
     DIM Ny   AS INTEGER                  '  Pseudo-normal
     DIM l1   AS INTEGER                  ' This is for general use
         
     DIM difx AS INTEGER     ' The X axis difference
     DIM dify AS INTEGER     ' The Y axis difference
     DIM cl   AS INTEGER     ' Used in many points..

     DIM ofs  AS LONG
     
     lx = 160  ' The starting position of the light source
     ly = 100  ' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     l1 = 0

  DO
     l1 = l1 + 4
     lx = CINT(160 + (COS(l1 / 13) * 99))
     ly = CINT(100 + (SIN(l1 / 23) * 99))
   ' ^^ those two make sure the light moves in a nice round path..

                             ' This were the important stuff is done
                             ' Here we will light the point x,y if lx,ly
                             '  is the light position
     ofs = 319
     vly = -ly               ' Calculate the L vector
    FOR y = 1 TO 198
     vly = vly + 1
     ofs = ofs + 2

     IF ((vly >= -128) AND (vly <= 128)) THEN
   
      vlx = -lx              ' >>>>>>>>>>>>>>>>>>>>>>
      FOR x = 1 TO 318
       vlx = vlx + 1

       IF ((vlx >= -128) AND (vlx <= 128)) THEN
       ' This is some stupid way to gain speed.. if the light vector is too
       '  far away from the point we want to light then don't bother..it
       '   will probably get no light..
       
        DEF SEG = VARSEG(vscr1(0))
        Nx = PEEK(ofs + 1) - PEEK(ofs - 1)
        Ny = PEEK(ofs + 320) - PEEK(ofs - 320)

       ' Those two lines are the heart of bumping
       ' We have a pixel, say x,y and we want to find how its normal vector
       '  is facing.. (that is its slope...) normaly we would have to mess
       '   with cos and sin and other shitty stuff but here we only care
       '    about something like a pseudo-normal.. in other words we only
       '     care about the Sign.. that is there are three possible pseudo
       '      normals:
       '      1) nx < 0 (Normal facing right)
       '         nx > 0 (Normal facing left)
       '         nx = 0 (Normal sticking out of the screen)
       '  and its the same story with ny.. (it can be facing up,down or
       '   sticking out..
       ' To find this orientation we get 2 pixels.. the one left and the
       '  one right (or the one up and the one down for ny) and we sub..
       '   the result is the N vector for our point 10,10

       ' The rest is easy.. we have two vectors now.. N,L.. we want
       '  their coordinates to be as close as possible (the closer they
       '   are the more light gets the pixel)
       
        cl = ABS(vlx - Nx)
        ' that is what I just said written in mathematics hehehe
        IF (cl > 127) THEN   ' Just not to overflow
         difx = 0
        ELSE
         difx = 127 - cl
        END IF
       ' ^^^^ that is the first component of the final color.. the
       '  light we get from the X axis

        ' Now we do the same stuff for the Y axis
        cl = ABS(vly - Ny)
        IF (cl > 127) THEN
         dify = 0
        ELSE
         dify = 127 - cl
        END IF
 
        cl = difx + dify
        ' finaly we add the two intensities and we're done..
       
        IF (cl > 128) THEN
         DEF SEG = VARSEG(vscr2(0))
         POKE ofs, cl        ' That's it.. put the damn pixel
        END IF
       END IF

       ofs = ofs + 1
      NEXT x
   
     ELSE
      ofs = ofs + 318
     END IF
  
    NEXT y

     Flip32
     Cls32
 
  LOOP UNTIL INKEY$ > ""

END SUB

':::::::::::::::::::::::::::::::::::::::::::::::::
SUB Flip32
' This show the entire virtual screen 2

     SHARED Flip32cd() AS STRING * 1
   
     DEF SEG = VARSEG(Flip32cd(0))
     CALL absolute(VARSEG(vscr2(0)), VARPTR(Flip32cd(0)))
END SUB

':::::::::::::::::::::::::::::::::::::::::::::::::
SUB Pal (c AS INTEGER, r AS INTEGER, g AS INTEGER, b AS INTEGER)
' This sets the Red, Green and Blue values of a certain color
    
     OUT &H3C8, c
     OUT &H3C9, r
     OUT &H3C9, g
     OUT &H3C9, b
END SUB

':::::::::::::::::::::::::::::::::::::::::::::::::
SUB SetupPal
' We are using a linear pallete..this procedure creates the one we use
' It looks better if you build one with the phong illumination model
'  but this is not a tutorial on how to setup palletes :)
    
     DIM i AS INTEGER        ' General purpose
      
    FOR i = 0 TO 255         ' this makes everything black
     Pal i, 0, 0, 0
    NEXT i
   
  ' We start from 128 and go all the way to 255..we dont light all
  '  256 colours cause it wont look much like a spotlight.. you can
  '   try it though
   
    FOR i = 128 TO 255       ' Choose the colours you prefer.. never should
     Pal i, i \ 2, i \ 2, 0  '  you go more than 63 (128 div 2) though..
    NEXT i
    
END SUB


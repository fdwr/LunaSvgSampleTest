/*
Fire Tutorial
By Wikki of Fragmentaria, AKA Aaron Clemmer

The tutorial and demo program were written for the X2FTP
programming contest.  It is entered into catagory 1,
"Tutorials or Magazine Articles."  


Contact Info:   aaronc@bbs.gemlink.com

		Aaron Clemmer
		104 Battle Mountain Rd
		Amissville, Va 22002-9307 USA
*/

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "fire.h"

int main()
{
 int x=0,y=0;
 int ch = ' '; //== More variables... ==//

 atexit(b4exit);
 startmsg();
 set_mx();    //== Get into Mode X ==//
 randomize(); //== Guess... ==//
 set_pal();   //== Set our palette ==//

//== Initialize both arrays to 0 ==//
 for (y = 0; y <= 56; y++)
  {
   for (x = 0; x <= 80; x++)
    {
     current[y][x] = 0;
     working[y][x] = 0;
    }
  }

 do
  {
   flame(); //== Call the flame generator ==//
   if(kbhit()) //== See if user hit keyboard ==//
    {
     ch=getch();
    }
  } while (ch != 27);

 return(0);
}


void flame()
{
 int delta=0,i=0,x=0,y=0; //== General loops ==//
 int cl1=0,cl2=0,cl3=0,cl4=0,cl5=0,cl6=0;  //== color vals used in averaging ==//

//== generate bottom line of flame ==//
 for(i=0;i<80;i++)
  {
   if(random(10) < 5)
    {
     delta=random(2)*255;
    }
   working[55][i]=delta;
   working[56][i]=delta;
  }

//== Get averages for pixels surrounding a given pixel ==//
 for (y = 55; y >= 2; y--)
  {
   for (x = 1; x <= 79; x++)
    {
     cl1 = current[y + y_amt_1][x + x_amt_1];
     cl2 = current[y + y_amt_2][x + x_amt_2];
     cl3 = current[y + y_amt_3][x + x_amt_3];  //== Get your five numbers to
     cl4 = current[y + y_amt_4][x + x_amt_4];  //== use in averaging
     cl5 = current[y + y_amt_5][x + x_amt_5];
     cl6 = (cl1+cl2+cl3+cl4+cl5) /5;

     if (cl6 > opt_decay_at) cl6 -= opt_decay_by;  //== Decay value, or it would never fade ==//
     working[y-1][x] = cl6;  //== Assign the averaged color to the working array ==//
    }
  }

//== Copy current[][] to working[][] ==//
 for (y =0; y <= 56; y++)
  {
   for (x = 0; x <= 80; x++)
    {
     current[y][x] = working[y][x];
    }
  }

//== Dump current[][] to screen ==//
 dump2con();
}


void dump2con()
{
//== Write the buffer to the screen ==//

 _SI = (unsigned int)&current[0][0];
 asm mov di,0
 asm mov ax,0A000h
 asm mov es,ax
 asm mov cx,40*45  /* Change the 40 to 56 if you don't want the
			  flame to be cropped */
XF1:
 asm mov ax,ds:[si]
 asm add si,2
 asm mov dl,al
 asm mov ax,ds:[si]
 asm add si,2
 asm mov dh,al
 asm mov es:[di],dx
 asm add di,2
 asm dec cx
 asm jnz XF1
}


void set_pal()
{
//== First we shift our palette values... ==//
 int  i;

 for(i=0;i<768;i++)
  {
   pal[i] = pal[i] >> pal_darkness;
  }

//== ...then set our palette ==//
 _SI = (unsigned int)&pal[0];
 asm mov cx,768
 asm mov dx,0x03c8
 asm xor al,al
 asm out dx,al
 asm inc dx
l1:
 asm outsb
 asm dec cx
 asm jnz l1
}


void set_mx(void)
{
//== Your generic routine to set ModeX ==//
 asm CLD
 asm MOV AX,13h
 asm INT 10h
 asm CLI
 asm MOV DX,3c4h
 asm MOV AX,604h // Unchain VGA
 asm OUT DX,AX
 asm MOV AX,0F02h // All planes
 asm OUT DX,AX

 asm MOV DX,3D4h
 asm MOV AX,14h // Disable dword mode
 asm OUT DX,AX
 asm MOV AX,0E317h // Enable byte mode.
 asm OUT DX,AX
 asm MOV AL,9
 asm OUT DX,AL
 asm INC DX
 asm IN  AL,DX
 asm AND AL,0E0h // Duplicate each scan 8 times.
 asm ADD AL,7
 asm OUT DX,AL
}


void b4exit()
{
 asm mov ax,03h
 asm int 10h
}


void startmsg()
{
 printf(
	"ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿\n"
	"³                                                     8-8-95    ³\n"
	"³       Fire Demo Tutorial                                      ³\n"
	"³       By Wikki of Fragmentaria                                ³\n"
	"³       Contact me at:                                          ³\n"
	"ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´\n"
	"³           AARONC@BBS.GEMLINK.COM                              ³\n"
	"ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´\n"
	"³       Or e-mail Aaron Clemmer on this BBS:                    ³\n"
	"³           Locust Grove BBS                                    ³\n"
	"³           1(540)672-8760  8-N-1                               ³\n"
	"ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ\n");
 getch();
}

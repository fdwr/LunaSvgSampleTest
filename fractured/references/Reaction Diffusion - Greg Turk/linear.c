/*

This creates a one-dimensional graph of peaks and valleys that represent
the result of a reaction-diffusion system.

The particular system is one originally described by Alan Turing, and
a clear description of it can be found in:

  How Well Does Turing's Theory of Morphogenesis Work?
  Jonathan Bard and Ian Lauder
  Journal of Theoretical Biology, Vol. 45, No. 2, pp. 501-531.
  (June 1974)


Permission is granted to modify and/or distribute this program so long
as the program is distributed free of charge and this header is retained
as part of the program.

Copyright (c) Greg Turk, 1991

*/

#include <stdio.h>
#include <math.h>

extern double atof();
extern double drand48();
float frand();

/* screen stuff */

int xsize = 1000;
int ysize = 300;

#define  BLACK    0
#define  RED     10
#define  GREEN   20
#define  BLUE    30
#define  YELLOW  40
#define  CYAN    50
#define  MAGENTA 60
#define  WHITE  255

/* simulation variables */

#define MAX 1400

float a[MAX];			/* concentration of chemical "a" */
float b[MAX];			/* concentration of chemical "b" */

float da[MAX];			/* change in "a" */
float db[MAX];			/* change in "b" */

float ainit = 4;		/* initial concentration of "a" */
float binit = 4;		/* initial concentration of "b" */

float diff1 = 0.25;		/* diffusion rate for "a" */
float diff2 = 0.0625;		/* diffusion rate for "b" */

float beta[MAX];		/* random substrate */
float beta_init = 12;		/* initial value of substrate */
float beta_rand = 0.05;		/* random variation in substrate */

float react_speed = 1.0;	/* speed of reaction (versus diffusion) */

int ncells = 60;		/* number of cells in the line */

int interval = 100;		/* frequency of display */


/******************************************************************************
Main routine.
******************************************************************************/

main (argc,argv)
  int  argc;
  char *argv[];
{
  char *s;

  /* parse the command line arguments */

  while(--argc >0 && (*++argv)[0]=='-') {
    for(s = argv[0]+1; *s; s++)
      switch(*s) {
	case 's':
	  xsize = atoi (*++argv);
	  ysize = atoi (*++argv);
	  argc -= 2;
	  break;
	case 'n':
	  ncells = atoi (*++argv);
	  argc -= 1;
	  break;
	case 'r':
	  react_speed = atof (*++argv);
	  argc -= 1;
	  break;
	default:
	  break;
      }
  }

  /* set up graphics */

  window_corner (512 - xsize / 2, 20);
  init_graphics (xsize, ysize, 40);

  makecolor (BLACK, 0, 0, 0);
  makecolor (RED, 255, 0, 0);
  makecolor (GREEN, 0, 255, 0);
  makecolor (BLUE, 0, 0, 255);
  makecolor (CYAN, 0, 255, 255);
  makecolor (MAGENTA, 255, 0, 255);
  makecolor (YELLOW, 255, 255, 0);
  makecolor (WHITE, 255, 255, 255);

  turing (999999);

  /* busy wait */

  while (1);
}


/******************************************************************************
Compute Turing reaction-diffusion.
******************************************************************************/

turing(steps)
  int steps;
{
  int i,i0,i1,k;
  float adiff,bdiff;
  float rsp;

  rsp = react_speed / 16;

  /* initialize values of all cells */

  for (i = 0; i < ncells; i++) {
    a[i] = ainit;
    b[i] = binit;
    beta[i] = beta_init + frand (-beta_rand, beta_rand);
  }

  /* compute simulation steps */

  for (k = 1; k <= steps; k++) {

    /* compute one step */

    for (i = 0; i < ncells; i++) {

      /* wrap around the end of the line of cells */
      i0 = (i+ncells-1) % ncells;
      i1 = (i+1) % ncells;

      /* diffusion values for "a" and "b" */
      adiff = a[i0] + a[i1] - 2 * a[i];
      bdiff = b[i0] + b[i1] - 2 * b[i];

      /* save the reaction and diffusion values values */
      da[i] = rsp * (16 - a[i] * b[i]) + adiff * diff1;
      db[i] = rsp * (a[i] * b[i] - b[i] - beta[i]) + bdiff * diff2;
    }

    /* add the change in concentration */

    for (i = 0; i < ncells; i++) {
      a[i] += da[i];
      b[i] += db[i];
      if (b[i] < 0)
	b[i] = 0;
    }

    /* graph the values if it is time */

    if (k % interval == 0 || k == steps)
      draw_turing();
  }
}


/******************************************************************************
Draw the current chemical concentration in a Turing reaction-diffusion
system.
******************************************************************************/

draw_turing()
{
  int i;
  int x,y;
  int x_old,y_old;
  float min,max;
  float s,t;

  /* range of values for plot of concentration */

  min = -2;
  max = 10;

  /* plot concentration */

  clear_screen();

  x_old = y_old = 0;  /* to quiet lint */

  for (i = 0; i < ncells; i++) {

    s = (b[i] - min) / (max - min);
    y = (1 - s) * ysize;

    t = i / (float) (ncells - 1);
    x = t * xsize;

    if (i != 0)
      line (x, y, x_old, y_old, WHITE);

    x_old = x;
    y_old = y;
  }

  flushbuffers();
}


/******************************************************************************
Pick a random number between min and max.
******************************************************************************/

float frand(min, max)
  float min,max;
{
  return (min + drand48() * (max - min));
}


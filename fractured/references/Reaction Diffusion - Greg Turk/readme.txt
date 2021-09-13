		Reaction-Diffusion Examples

This directory contains two simple programs that generate patterns
using the chemical process known as reaction-diffusion.

The first of these programs is "linear", and it creates one-dimensional
graphs of (simulated) chemical concentration.  The chemical system
being simulated generates a semi-regular landscape of peaks and valleys.
By default, the simulation is performed on a line of 60 "cells" and
displayed in a window of dimensions 1000 by 300 pixels.  Here are the
command line options:

  -s <xsize> <ysize>   Change window dimensions.
  -n <ncells>          Set the number of cells to <ncells>.
  -r <rspeed>          Alter the reaction speed.  Default is 1.
		       Smaller values will give broader hills, and
		       values much larger than 1 will cause the
		       solution method to fail.

Running "linear" with the invocation "linear -n 200 -r .2" on a DECstation
5000 gives a pleasing animation of the pattern forming process.

The second program is "spots", and it can simulate either of two
reaction-diffusion systems, one for making spots and the other for
stripes.  By default, "spots" creates a set of spots on a 30 by 30
grid of cells.  Here are the command line options:

  -n <xsize> <ysize>   Change number of cells in grid.
  -x                   Draw stripes instead of spots.


These programs were written to be stripped-down examples of how to
simulate reaction-diffusion systems.  Any number of improvements are
possible, including:  access to more of the reaction parameters, better
user interface, simulation of other reaction-diffusion systems.  Both
programs use X11 to display the graphics, but the calls are isolated
and it should be simple to substitute your favorite graphics library.

For more information about reaction-diffusion, especially as it relates
to computer graphics, see the following two articles:

  "Generating Textures on Arbitrary Surfaces Using Reaction-Diffusion"
  Greg Turk
  Computer Graphics, Vol. 25, No. 4, pp. 289-298
  July 1991 (SIGGRAPH '91)

  "Reaction-Diffusion Textures"
  Andrew Witkin and Michael Kass
  Computer Graphics, Vol. 25, No. 4, pp. 299-308
  July 1991 (SIGGRAPH '91)

The bibliographies of these papers are reasonable jumping-off points
into the reaction-diffusion literature.


Greg Turk (turk@cs.unc.edu)
August 1991
updated July 1992

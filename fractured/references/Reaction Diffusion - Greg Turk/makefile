# spots by reaction-diffusion

CFLAGS = -O -I. -I/usr/include
LIBS = -lX11 -lm

OBJ1 = linear.o graphics.o
OBJ2 = spots.o graphics.o

current: spots linear

linear: $(OBJ1) makefile
	cc -o linear $(OBJ1) $(LIBS) $(CFLAGS)

spots: $(OBJ2) makefile
	cc -o spots $(OBJ2) $(LIBS) $(CFLAGS)


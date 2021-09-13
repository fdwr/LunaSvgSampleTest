/**
graphics.c
*/

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#include <stdlib.h>

#define ProgramTitle "Reaction Diffusion demo - Greg Turk"
#define INIT_WINDOW_SIZE 300
#define FIELD_SIZE 60

void Display (void);
void Keyboard( unsigned char c, int x, int y );


static int MainWindow = 0;

init_graphics(int w, int h, int ncolors)
{
	glutInitDisplayMode( GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH );

	// set the initial window configuration:
	glutInitWindowPosition( 0, 0 );
	glutInitWindowSize( INIT_WINDOW_SIZE, INIT_WINDOW_SIZE );

	// open the window and set its title:
	MainWindow = glutCreateWindow( ProgramTitle );
	glutSetWindowTitle( ProgramTitle );

	// setup the clear values:
	//glClearColor( BACKCOLOR[0], BACKCOLOR[1], BACKCOLOR[2], BACKCOLOR[3] );
	glutSetWindow( MainWindow );
	glClearColor( 0,0,0,0 );
	glEnable(GL_COLOR_MATERIAL);
	glEnable( GL_BLEND );
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DITHER);
	glDepthFunc(GL_LEQUAL);

	glutDisplayFunc( Display );
	//glutReshapeFunc( Resize );
	glutKeyboardFunc( Keyboard );

}


enum { ESCAPE = 0x1b };

void Keyboard( unsigned char c, int x, int y )
{

	switch ( c )
	{
	case 'q':
	case 'Q':
	case ESCAPE:
		glFinish();
		glutDestroyWindow( MainWindow );
		//glutLeaveMainLoop() // supported by GLUT 2.4
		exit( 0 );
	}

	// force a call to Display():
	glutSetWindow( MainWindow );
	glutPostRedisplay();
}


void enter_loop(void (*idleness)())
{
  /* make spots or stripes */
	glutIdleFunc((void(*)(void)) idleness);
	glutPostRedisplay();
	glutMainLoop();
}


void Display (void)
{
	GLsizei vx, vy, v;		// viewport dimensions
	GLint xl, yb;		// lower-left corner of viewport

	// set which window we want to do the graphics into:
	glutSetWindow( MainWindow );

	// erase the background:
	//glDrawBuffer( GL_BACK );
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	//glEnable( GL_DEPTH_TEST );

	// specify shading to be flat:
	glShadeModel( GL_SMOOTH ); //GL_FLAT

	// set the viewport to a square centered in the window:
	vx = glutGet( GLUT_WINDOW_WIDTH );
	vy = glutGet( GLUT_WINDOW_HEIGHT );
	v = vx < vy ? vx : vy;			// minimum dimension
	xl = ( vx - v ) / 2;
	yb = ( vy - v ) / 2;
	glViewport( xl, yb,  v, v );

	// set the viewing volume:
	// remember that the Z clipping  values are actually
	// given as DISTANCES IN FRONT OF THE EYE
	// ONLY USE gluOrtho2D() IF YOU ARE DOING 2D !
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();

	glOrtho( 0, FIELD_SIZE,  0, FIELD_SIZE,    -0.1, 1000. );

	// place the objects into the scene:
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();

	glColor3ub(255,0,0);
	glBegin( GL_POLYGON );
	//glColor3ub(output,output,output);
	//glVertex2f(i,j);
	glVertex2f(0,0);
	glVertex2f(64,0);
	glVertex2f(0,64);
	glEnd();


	// set the eye position, look-at position, and up-vector:
	// IF DOING 2D, REMOVE THIS -- OTHERWISE ALL YOUR 2D WILL DISAPPEAR !
	//gluLookAt( 0., 0., 2.5,     0., 0., 0.,     0., 1., 0. );

	// translate the objects in the scene:
	// note the minus sign on the z value
	// this is to make the appearance of the glui z translate
	// widget more intuitively match the translate behavior
	// DO NOT TRANSLATE IN Z IF YOU ARE DOING 2D !
	//glTranslatef( (GLfloat)TransXYZ[0], (GLfloat)TransXYZ[1], -(GLfloat)TransXYZ[2] );

	// swap the double-buffered framebuffers:
	glutSwapBuffers();

	// be sure the graphics buffer has been sent:
	glFlush();
}


void set_pixel_size(int psize)
{
	// just ignore...
}


void writepixel (int i, int j, int output)
{
	/*
	glBegin( GL_POINTS );
	glColor3ub(output,output,output);
	glVertex2f(i,j);
	glEnd();
	*/
	glColor3ub(output,output,output);
	glBegin( GL_QUADS );
	glVertex2f(i,j);
	glVertex2f(i+1,j);
	glVertex2f(i+1,j+1);
	glVertex2f(i,j+1);
	glEnd();

	/*glColor3ub(0,255,0);
	glBegin( GL_POLYGON );
	//glColor3ub(output,output,output);
	//glVertex2f(i,j);
	glVertex2f(0,0);
	glVertex2f(64,0);
	glVertex2f(0,64);
	glEnd();*/
}


void flushbuffers()
{
	glFlush();
	glutSwapBuffers();
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}

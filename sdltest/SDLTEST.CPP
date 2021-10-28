// File: sdltest.cpp
// Author: Dwayne Robinson
// Date: 2005-09-05
//
////////////////////////////////////////////////////////////////////////////////

#include <stdlib.h>
#include <tchar.h>
#include <basictypes.h>

#include "SDL.h"

#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#include <windows.h>

////////////////////////////////////////////////////////////////////////////////
// pointless forward refs

void FatalMsg(TCHAR* msg);

////////////////////////////////////////////////////////////////////////////////
// global vars

SDL_Surface* sdlScreen;
SDL_Event sdlEvent;

int APIENTRY WinMain(
    HINSTANCE hInstance,
    HINSTANCE hPrevInstance,
    LPSTR lpCmdLine,
    int nCmdShow
    )
{
    // TODO: Place code here.
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0)
    {
        FatalMsg("Could not initialize SDL (Simple DirectMedia Library).");
    };
    atexit(SDL_Quit);

    sdlScreen = SDL_SetVideoMode(640, 480, 8, SDL_SWSURFACE|SDL_ANYFORMAT);
    if (sdlScreen == nullptr)
    {
        FatalMsg("Could not set video mode.");
        //fprintf(stderr, "Couldn't set 640x480x8 video mode: %s\n",
        //                SDL_GetError());
        exit(1);
    }	

    SDL_Surface* image = SDL_LoadBMP(T("sdltest.bmp"));
    if (image == nullptr)
    {
        FatalMsg("Couldn't load %s: %s\n"); //, file_name, SDL_GetError());
        exit(-1);
    }

    // Palettized screen modes will have a default palette (a standard
    // 8*8*4 colour cube), but if the image is palettized as well we can
    // use that palette for a nicer colour matching
    if (image->format->palette && sdlScreen->format->palette)
    {
        SDL_SetColors(
            sdlScreen,
            image->format->palette->colors,
            0,
            image->format->palette->ncolors
        );
    }

    /* Blit onto the screen surface */
    if (SDL_BlitSurface(image, nullptr, sdlScreen, nullptr) < 0)
    {
        FatalMsg("BlitSurface error: %s\n"); //, SDL_GetError());
    }

    SDL_UpdateRect(sdlScreen, 0, 0, image->w, image->h);

    // Poll for events. SDL_PollEvent() returns 0 when there are no
    // more events on the event queue, our while loop will exit when
    // that occurs.
    while (SDL_WaitEvent(&sdlEvent) >= 0)
    {
        // We are only worried about SDL_KEYDOWN and SDL_KEYUP events
        switch (sdlEvent.type)
        {
        case SDL_KEYDOWN:
            //printf("Key press detected\n");
            break;

        case SDL_KEYUP:
            //printf("Key release detected\n");
            break;

        case SDL_QUIT:
            goto OutOfMainLoop;
        default:
            break;
        }
        //SDL_Delay(30);
    }
OutOfMainLoop:
    
    /* Free the allocated BMP surface */
    SDL_FreeSurface(image);
    
    exit(0);
    return 0; // what was the compiler option to rid the dummy return?
}

void FatalMsg(TCHAR* msg)
{
    MessageBox(nullptr, "Fatal error. Ending program.", msg, MB_OK);
    exit(-1);
}

#ifdef _CONSOLE
int main(int argc, char* argv[])
{
    // Body of the program goes here.
    return 0;
}
#endif

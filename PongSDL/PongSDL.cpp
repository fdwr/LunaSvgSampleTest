// File: sdltest.cpp
// Author: Dwayne Robinson
// Date: 2005-09-05
//
////////////////////////////////////////////////////////////////////////////////

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
//#include <basictypes.h>

#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#include <windows.h>

#include "SDL.h"
#include "SDL_syswm.h"

////////////////////////////////////////////////////////////////////////////////
// pointless forward refs

void FatalMsg(char const* msg);

////////////////////////////////////////////////////////////////////////////////
// global vars

SDL_Surface* sdlScreen;
SDL_Event sdlEvent;

struct Tensor2D
{
    int32_t x, y;
};
using Point2D = Tensor2D;
using Size2D = Tensor2D;
using Vector2D = Tensor2D;

struct Sprite
{
    Point2D origin;
    Point2D hotSpot;
    Size2D size;
};

class GameState
{
public:
    struct Paddle
    {
        Point2D position = {};
    };

    struct Ball
    {
        Point2D position = {};
        Vector2D velocity = {};
    };

    Paddle paddle1;
    Paddle paddle2;
    Ball ball;
};

constexpr uint32_t fieldSizeX = 800;
constexpr uint32_t fieldSizeY = 640;

GameState gameState;

constexpr Sprite paddleSprite =
{
    .origin = {80,0},
    .hotSpot = {88,32},
    .size = {16,64},
};

constexpr Sprite ballSprite =
{
    .origin = {0,0},
    .hotSpot = {32,32},
    .size = {64,64},
};

void InitializeGameState(GameState& gameState)
{
    gameState.ball.position.x = fieldSizeX / 2;
    gameState.ball.position.y = fieldSizeY / 2;
    gameState.ball.velocity.x = 4;
    gameState.ball.velocity.y = 4;
    gameState.paddle1.position.x = paddleSprite.size.x;
    gameState.paddle1.position.y = fieldSizeY / 2;
    gameState.paddle2.position.x = fieldSizeX - paddleSprite.size.x;
    gameState.paddle2.position.y = fieldSizeY / 2;

}

void DrawSprite(SDL_Surface* image, Point2D point, Sprite const& sprite)
{
    int32_t x = point.x + sprite.origin.x - sprite.hotSpot.x;
    int32_t y = point.y + sprite.origin.y - sprite.hotSpot.y;
    SDL_Rect sourceRect = {int16_t(sprite.origin.x), int16_t(sprite.origin.y), uint16_t(sprite.size.x), uint16_t(sprite.size.y)};
    SDL_Rect destRect = {int16_t(x), int16_t(y), uint16_t(sprite.size.x), uint16_t(sprite.size.y)};

    SDL_BlitSurface(image, &sourceRect, sdlScreen, &destRect);
}

void UpdateBallPosition(GameState& gameState)
{
    if (gameState.ball.position.x <= -ballSprite.size.x || gameState.ball.position.x >= int32_t(fieldSizeX + ballSprite.size.x))
    {
        // Ball exited field. End round.
        gameState.ball.position.x = fieldSizeX / 2;
        gameState.ball.position.y = fieldSizeY / 2;
    }
    else if (int32_t dif = gameState.ball.position.y - int32_t(ballSprite.size.y / 2); dif < 0)
    {
        // Hit field top. So reflect direction.
        gameState.ball.position.y -= dif;
        gameState.ball.velocity.y = -gameState.ball.velocity.y;
    }
    else if (int32_t dif = gameState.ball.position.y - int32_t(fieldSizeY - ballSprite.size.y / 2); dif > 0)
    {
        // Hit field bottom. So reflect direction.
        gameState.ball.position.y -= dif;
        gameState.ball.velocity.y = -gameState.ball.velocity.y;
    }
    gameState.ball.position.x += gameState.ball.velocity.x;
    gameState.ball.position.y += gameState.ball.velocity.y;
}

void CheckPaddleInput(uint8_t const* keys, uint32_t keyCount)
{
    assert(keyCount >= SDLK_LAST);

    constexpr int32_t paddleVelocity = 8;
    int32_t delta = 0;

    // keys is at least as great as 
    if (keys[SDLK_UP])
    {
        delta = -paddleVelocity;
    }
    else if (keys[SDLK_DOWN])
    {
        delta = paddleVelocity;
    }
    gameState.paddle1.position.y += delta;
}

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

    sdlScreen = SDL_SetVideoMode(fieldSizeX, fieldSizeY, 32, SDL_SWSURFACE|SDL_ANYFORMAT);
    if (sdlScreen == nullptr)
    {
        FatalMsg("Could not set video mode.");
        //fprintf(stderr, "Couldn't set 640x480x8 video mode: %s\n",
        //                SDL_GetError());
        exit(1);
    }

    HWND window = GetActiveWindow();
    SetWindowText(window, "Pong");

    SDL_Surface* image = SDL_LoadBMP("Pong atlas texture.bmp");
    if (image == nullptr)
    {
        FatalMsg("Couldn't load %s: %s\n"); //, file_name, SDL_GetError());
        exit(-1);
    }

    InitializeGameState(gameState);

    uint32_t backgroundColor = SDL_MapRGB(sdlScreen->format, 0, 0, 0);

    // Poll for events. SDL_PollEvent() returns 0 when there are no
    // more events on the event queue, our while loop will exit when
    // that occurs.

    while (true)
    {
        // React to keypresses (polled held-down keys are checked later).
        while (SDL_PollEvent(&sdlEvent))
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

        }

        int32_t keyCount;
        uint8_t* keys = SDL_GetKeyState(&keyCount);
        CheckPaddleInput(keys, keyCount);

        SDL_FillRect(sdlScreen, nullptr, backgroundColor);

        DrawSprite(image, gameState.ball.position, ballSprite);
        DrawSprite(image, gameState.paddle1.position, paddleSprite);
        DrawSprite(image, gameState.paddle2.position, paddleSprite);

        //SDL_UpdateRect(sdlScreen, 0, 0, image->w, image->h);
        //SDL_UpdateRect(sdlScreen, 0, 0, 0, 0);
        SDL_Flip(sdlScreen);

        UpdateBallPosition(gameState);

        SDL_Delay(33);
    }
OutOfMainLoop:
    
    /* Free the allocated BMP surface */
    SDL_FreeSurface(image);
    
    exit(0);
    return 0; // what was the compiler option to rid the dummy return?
}

void FatalMsg(char const* msg)
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

See [SpriteView.txt](doc/SpriteView.txt) and [Building.txt](doc/Building.txt).

This is an ancient DOS project in x86 asm, not actively updated anymore, but here's the source for those who asked. Should I clean it up more? Yes. Will I? Nope.

![Scene Viewer](doc/ScreenShot0.png "Viewing sprite graphics in Dottie Dreads Nought by Goldlocke https://goldlocke.itch.io/dottie-dreads-nought")

![VRAM Graphics Viewer](doc/ScreenShot1.png "Viewing raw icons in C:\Windows\SystemResources\shell32.dll.mun")

TODO: : : : : 

Source files:
- src/BgMapper.asm - Main entry point and most logic
- src/BgmFuncs.asm - All of the helper routines for this prog
- src/BgTile.asm - Tile conversion, savestate loading, scene rendering
- src/Memory.inc - Memory allocation (Thanks to Gaz)
- src/System.inc - Program startup/shutdown

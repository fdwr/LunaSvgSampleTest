
## What is it?

✋ There are better viewing programs out there now. This is an ancient (~1999) DOS utility in x86 asm to view raw graphics in files, and it's not actively updated anymore, but here's the source for those who asked. Should I clean it up more? Yes. Will I? Nope.

See [Project Page](http://pikensoft.com/programs-spriteview.html) and [BgMapper.txt](doc/SpriteView.txt) for more.

![Dottie Dreads Nought](doc/ScreenShot0.png)<br/>
<small>Sprite graphics in <a href="https://goldlocke.itch.io/dottie-dreads-nought">Dottie Dreads Nought by Goldlocke</a></small>

![Shell32 icons](doc/ScreenShot1.png)<br/>
<small>Raw icons in C:\Windows\SystemResources\shell32.dll.mun</small>

## Building

See [Building.txt](doc/Building.txt):

todo:
Source files:
- src/BgMapper.asm - Main entry point and most logic
- src/BgmFuncs.asm - All of the helper routines for this prog
- src/BgTile.asm - Tile conversion, savestate loading, scene rendering
- src/Memory.inc - Memory allocation (Thanks to Gaz)
- src/System.inc - Program startup/shutdown

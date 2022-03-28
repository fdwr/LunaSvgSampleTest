# LunaSvgTest

Dwayne Robinson 2022-03-21

## What
Just a test of LunaSvg to see how it works and if I can extend it (it's wonderfully stand-alone with no large framework dependencies like Skia or Cairo), making it very easy to integrate into an existing project that has a memory bitmap.

## Usage
- **OS**: Windows 7+
- **Installation**: Portable app, and so just unzip the files into a folder where you want them - no bloated frameworks or dependencies needed.
- **Running**: Double click LunaSvgTest.exe, and open the file(s) you want or drag&drop files.
- **License**: [License.txt](License.txt) tldr: Do pretty much whatever you want with the binary at no cost, except the icons are copyrighted by others.

## Building
- Open the CMake project with Visual Studio (confusingly you have to open the project via "Open Folder" instead of Open Project).

## Features
- Open simple non-animated SVG's. I've seen a few fail to load in LunaSvg if they use other units (like "1em"), but otherwise every one I've tried load.
- Multiple sizes: fixed size, natural size, window size, waterfall display
- Pixel zoom: to see the actual rendering up close
- Grid display

## Related

- LunaSVG - https://github.com/sammycage/lunasvg
- SVG specification - https://github.com/w3c/svgwg/tree/master

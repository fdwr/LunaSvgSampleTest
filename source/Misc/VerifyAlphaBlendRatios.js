// Just verifies that alpha blending equations match.
// Running:
// > set NODE_SKIP_PLATFORM_CHECK=1    // for Windows 7
// > node-v18.4.0-win-x64\node.exe VerifyAlphaBlendRatios.js

'use strict'

var mismatchCount = 0
for (var i = 0; i < 255; ++i)
{
    for (var j = 0; j < 255; ++j)
    {
        var a = Math.floor((i * j) / 255)
        var b = (i * j)
        b = (b + 1 + (b >> 8)) >> 8
        if (a != b)
        {
            console.log('[', i, j, '] =', a, b)
            ++mismatchCount
        }
    }
}

// var fs = require('fs')
// fs.writeFile('out.txt', 'File data', function (err) {});

console.log('Mismatch count: ', mismatchCount)

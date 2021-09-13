#region Using Statements
using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Graphics.PackedVector;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Storage;
using System.Diagnostics; // for assert() which should be BUILT IN!
#endregion

namespace Plain
{
    
class UcGroup : UcWindow
{

    public UcGroup(Uc parent, PackerDelegate initialPacker)
        : base(parent, initialPacker)
    {
        margin = new Rectangle(0, 0, 0, 0);
        spacing = 8;
    }

}

}

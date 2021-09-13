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
    
class UcImage : Uc
{
    TextureRectangle Image;

    public UcImage(Uc parent, TextureRectangle initialImage)
    {
        Debug.Assert(initialImage.texture != null);
        Image = initialImage;
        Hints.Set(HintBits.NoKeyFocus);
        parent.InsertChild(this);
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        batch.Draw(
            Image.texture,
            new Rectangle(rect.X, rect.Y, rect.Height, rect.Width),
            Image.rectangle,
            Image.color
            );
        return 0;
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Packed)
        {
            return Image.rectangle;
        }
        return base.PositionQuery(mode);
    }
}

}

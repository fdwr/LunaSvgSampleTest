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
    
/// Basically an embedded group with a border.
/// Use a group instead if you want no visible outline or text.
class UcFrame : UcWindow
{
    public override string Text
    {
        get { return text; }
        set
        {
            text = value;
            HintBits.SetNeedRepack(this);
        }
    }
    string text;


    public UcFrame(Uc parent, string initialText, PackerDelegate initialPacker)
        : base(parent, initialPacker)
    {
        Packer = (initialPacker != null) ? initialPacker : UcWindow.PackerCol;//.PackInward;
        margin = new Rectangle(8, 8, 8, 8);
        spacing = 8;

        text = initialText;
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        Color color = (Hints.IsDisabled) ? new Color(255, 255, 255, 128) : Color.White;
        int srcx
            //= (parentFlags.IsDisabled) ? 120
            = (Hints.IsKeyFocused) ? 244
            : 212;

        batch.Draw( // top left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y, 12, 12),
            new Rectangle(srcx, 84, 12, 12),
            color
            );
        batch.Draw( // top right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 12, rect.Y, 12, 12),
            new Rectangle(srcx + 20, 84, 12, 12),
            color
            );
        batch.Draw( // bottom left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y + rect.Height - 12, 12, 12),
            new Rectangle(srcx, 84+24, 12, 12),
            color
            );
        batch.Draw( // bottom right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 12, rect.Y + rect.Height - 12, 12, 12),
            new Rectangle(srcx + 20, 84+24, 12, 12),
            color
            );

        batch.Draw( // left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y + 12, 12, rect.Height - 12 - 12),
            new Rectangle(srcx, 84+12, 12, 1),
            color
            );
        batch.Draw( // right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 12, rect.Y + 12, 12, rect.Height - 12 - 12),
            new Rectangle(srcx + 20, 84+12, 12, 1),
            color
            );
        batch.Draw( // top
            PlainMain.Style,
            new Rectangle(rect.X + 12, rect.Y, rect.Width - 12 - 12, 12),
            new Rectangle(srcx + 12, 84, 1, 12),
            color
            );
        batch.Draw( // bottom
            PlainMain.Style,
            new Rectangle(rect.X + 12, rect.Y + rect.Height - 12, rect.Width - 12 - 12, 12),
            new Rectangle(srcx + 12, 84+24, 1, 12),
            color
            );
        batch.Draw( // middle
            PlainMain.Style,
            new Rectangle(rect.X + 12, rect.Y + 12, rect.Width - 12 - 12, rect.Height - 12 - 12),
            new Rectangle(srcx + 12, 84+12, 1, 1),
            color
            );

        if (text != null)
        {
            // todo: Label, pay attention to alignment
            batch.DrawString(PlainMain.Font, text, new Vector2(rect.X + 9f, rect.Y + 9f), new Color(0, 0, 0, color.A));
            batch.DrawString(PlainMain.Font, text, new Vector2(rect.X + 8, rect.Y + 8), color);
        }

        return base.Draw(gd, rect, batch);
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Minimum)
        {
            return new Rectangle(0, 0, 8*2, 8*2);
        }
        else if (mode == PositionEnum.Packed)
        {
            if (text != null)
            {
                Vector2 size = PlainMain.Font.MeasureString(text);
                margin.Y = 8 + (int)size.Y + 8;
                Rectangle rect = base.PositionQuery(mode);
                if (rect.Width < (int)size.X) rect.Width = (int)size.X;
                return rect;
            }
            else
            {
                margin.Y = 8;
                return base.PositionQuery(mode);
            }
        }
        else
        {
            return base.PositionQuery(mode);
        }
    }
}

}

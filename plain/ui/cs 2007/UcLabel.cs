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
    
class UcLabel : Uc
{
    public override string Text { 
        get { return text; }
        set { 
            text = value;
            HintBits.SetNeedRepack(this);
        }
    }
    string text;

    public override float Value
    {
        // TryParse completely ignores my number style specification.
        // I want the parser to ignore anything past the decimal
        // point, and only return the integral portion - not return zero!
        //int.TryParse("123", System.Globalization.NumberStyles.Number, null, out result);
        //int.TryParse(text, out result);
        // Ugh, compact framework does not have tryParse for Xbox
        // Fine, I'll just write my own... :-/
        get { return (int) PlainUtils.ParseNumber(text); }
        set { text = value.ToString(); }
    }
    public override int ValueInt
    {
        get { return (int)PlainUtils.ParseNumberInt(text); }
        set { text = value.ToString(); }
    }

    public UcLabel(Uc parent, string initialText)
    {
        Debug.Assert(parent != null);
        //Debug.Assert(initialText != null);
        if (initialText == null) initialText = string.Empty;

        Hints.Set(HintBits.NoKeyFocus | HintBits.NoMouseFocus);
        text = initialText;
        parent.InsertChild(this);
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        Color color = (Hints.IsDisabled) ? new Color(255, 255, 255, 128) : Color.White;
        // todo: Label, pay attention to alignment
        batch.DrawString(PlainMain.Font, text, new Vector2(rect.X + 1f, rect.Y + 1f), new Color(0, 0, 0, color.A));
        batch.DrawString(PlainMain.Font, text, new Vector2(rect.X, rect.Y), color);
        return 0;
        //return base.Draw(gd, rect, batch, font);
    }

    public override int MousePoll(MouseMessage ms)
    {
        if (ms.LeftButton == ButtonRelative.Pressed)
        {
            //Flags.Toggle(FlagsEnum.Disabled);
        }
        return 0;
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Packed)
        {
            Vector2 size = PlainMain.Font.MeasureString(text);
            Rectangle rect = new Rectangle(0, 0, (int)size.X, (int)size.Y);
            
            return rect;
        }
        return base.PositionQuery(mode);
    }
}

}

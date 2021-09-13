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
    
class UcButton : Uc
{
    public override string Text
    {
        get { return text; }
        set { 
            text = value;
            HintBits.SetNeedRepack(this);
        }
    }
    public override int ValueInt
    {
        get { return (int)(state & StateFlags.Down); }
        set { state = (state & ~StateFlags.Down) | (StateFlags)(value & 1); }
    }

    /// Sends the current value of the button (pressed/unpressed)
    public delegate void ActionDelegate(Uc uc, int value);
    public ActionDelegate ActionCallback; // make a multicast delegate instead?? (event)

    ////////////////////
    // private
    string text;

	enum StateFlags {
		Down=1<<0,
		Lock=1<<1,
		Toggle=1<<2,
	};
    StateFlags state;


    public UcButton(Uc parent, string initialText, ActionDelegate callback)
    {
        Debug.Assert(parent != null);
        Debug.Assert(initialText != null);

        text = initialText;
        ActionCallback = (callback != null) ? callback : ActionCallbackIntDummy;
        Position = PositionPacked = new Rectangle(0, 0, 96, 32);

        parent.InsertChild(this);
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        Color color = (Hints.IsDisabled) ? new Color(255, 255, 255, 128) : Color.White;
        int stateXoffset =
            ((state & StateFlags.Down) != 0) ? 108 :
            (Hints.IsKeyFocused) ? 72 :
            0;
        int scaledHeight = rect.Height * 36 / 32;

        batch.Draw( // left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y, 12, scaledHeight),
            new Rectangle(stateXoffset, 0, 12, 36),
            color
            );
        batch.Draw( // right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 12, rect.Y, 16, scaledHeight),
            new Rectangle(20+stateXoffset,0,16,36),
            color
            );
        batch.Draw( // middle
            PlainMain.Style,
            new Rectangle(rect.X + 12, rect.Y, rect.Width - 24, scaledHeight),
            new Rectangle(12 + stateXoffset, 0, 4, 36),
            color
            );
        
        // center horizontally and vertically
        Vector2 textPos = new Vector2(rect.Width, rect.Height);
        textPos -= PlainMain.Font.MeasureString(text);
        textPos = new Vector2(rect.X + (int)(textPos.X / 2), rect.Y + (int)(textPos.Y / 2));
        // *the cast to int is to prevent blurry text

        //Color textColor = ((state & StateFlags.Down) != 0) ?  Color.White : Color.Gray;
        //Color textColor = (Flags.IsMouseFocused) ?  Color.White : Color.Gray;
        batch.DrawString(PlainMain.Font, text, textPos + new Vector2(1, 1), new Color(0,0,0,color.A));
        batch.DrawString(PlainMain.Font, text, textPos, color);
        return 0;
        //return base.Draw(gd, rect, batch, font);
    }

    public override int MousePoll(MouseMessage ms)
    {
        if (ms.LeftButton == ButtonRelative.Pressed)
        {
            FocusCapture(this);
            // the mousein usually already captures focus
            // but it is possible to tab away then click
            Activate(true);
        }
        else if (ms.LeftButton == ButtonRelative.Released)
        {
            Activate(false);
        }
        return 0;
    }

    public override int MouseIn(MouseMessage ms)
    {
        Parent.FocusCapture(this);
        return 0;
    }

    public override int MouseOut(MouseMessage ms)
    {
        CancelActivate();
        return 0;
    }

    // 2005-04-12
    void Activate(bool mode)
    {
	    StateFlags prestate = state;
	    bool trigger = true;
	    if ((state & StateFlags.Lock) != 0) {
            if (mode) state |= StateFlags.Down;
	    }
	    else if ((state & StateFlags.Toggle) != 0) {
            state ^= StateFlags.Down;
	    }
	    else {
	    	if (mode)	{state |= StateFlags.Down; trigger = false;}
	    	else		{state &= ~StateFlags.Down;}
	    }
	    if (state != prestate) {
	    	//redraw(::redrawPartial);
	    	if (trigger) {			
	    		// send owner message
	    		//owner->code(this, ButtonObj::msg::click);
                ActionCallback(this, (int)(state & StateFlags.Down));
	    	}
	    }
    }

    void CancelActivate()
    {
        if ((state & (StateFlags.Lock | StateFlags.Toggle)) == 0)
            state &= ~StateFlags.Down;
    }

    public override int FocusOut()
    {
        CancelActivate();
        return base.FocusOut();
    }

    public override int KeyPress(KeyboardMessage ks)
    {
        if (ks.ButtonCode == Keys.Space) 
            Activate(true);
        return 0;
    }

    public override int KeyRelease(KeyboardMessage ks)
    {
        if (ks.ButtonCode == Keys.Space) 
            Activate(false);
        return 0;
    }

    public override int Navigate(NavigateMessage ns)
    {
        if (ns.Command == NavigateCommand.Enter) {
            ActionCallback(this, (int)(state & StateFlags.Down));
            return 0;
        };
        return -1;
        //return base.Navigate();
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Minimum || mode == PositionEnum.Packed) 
        {
            Vector2 size = PlainMain.Font.MeasureString(text);
            Rectangle rect = new Rectangle(0, 0, (int)size.X + 24, (int)size.Y + 8);
            if (mode == PositionEnum.Packed) {
                if (rect.Width < 96) rect.Width = 96;
                if (rect.Height < 32) rect.Height = 32;
            }
            
            return rect;
        }
        return base.PositionQuery(mode);
    }
}

}

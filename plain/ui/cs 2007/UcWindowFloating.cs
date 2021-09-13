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

/** Summary: Arranges a line of controls, horizontally or vertically.
*/
using ActionDelegate = UcTitle.ActionDelegate;

class UcWindowFloating : UcWindow
{
    public ActionDelegate ActionCallback; // make a multicast delegate instead?? (event)

    public override string Text
    {
        get { return text; }
        set {
            text = value;
            if (TitleControl != null)
            {
                // set visibility of title bar based on text
                if (text == null)
                    TitleControl.Hints.Set(HintBits.Hidden);
                else
                    TitleControl.Hints.Clear(HintBits.Hidden);
                HintBits.SetNeedRepack(TitleControl);
            }
            else if (text != null)
            {
                TitleControl = new UcTitle(this, text, TitleControlCallback);
                InsertChild(TitleControl);
            }
        }
    }
    string text;

    protected UcTitle TitleControl;

    public UcWindowFloating(Uc parent, string initialText)
    : this(
        parent,
        initialText,
        null,
        null
        )
    {
    }


    public UcWindowFloating(Uc parent, string initialText, PackerDelegate initialPacker, ActionDelegate initialCallback)
        : base()
    {
        Hints.Set(HintBits.Floating);
        Packer = (initialPacker != null) ? initialPacker : UcWindow.PackerCol;//.PackInward;
        margin = new Rectangle(8, 8, 8, 8);
        spacing = 8;
        
        text = initialText;
        if (initialText != null)
        {
            TitleControl = new UcTitle(this, initialText, TitleControlCallback);
            TitleControl.Hints.Set(HintBits.PackTop | HintBits.PackWide | HintBits.PackHorizontal);
            TitleControl.State = UcTitle.StateFlags.Close | UcTitle.StateFlags.Collapse;
            InsertChild(TitleControl);
        }
        
        ActionCallback = initialCallback;

        if (parent != null)
            parent.InsertChild(this);
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        /*
        batch.Draw(
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y, rect.Width, rect.Height),
            new Rectangle(0,40, 440, 1),
            Color.White
            );
        */
        int srcx
            //= (parentFlags.IsDisabled) ? 120
            = (Hints.IsKeyFocused) ? 0
            : 80;

        batch.Draw( // top left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y, 16, 24),
            new Rectangle(srcx, 48, 16, 24),
            Color.White
            );
        batch.Draw( // top right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 16, rect.Y, 32,24),
            new Rectangle(srcx + 48, 48, 32, 24),
            Color.White
            );
        batch.Draw( // bottom left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y + rect.Height - 16, 24,28),
            new Rectangle(srcx, 96, 24, 28),
            Color.White
            );
        batch.Draw( // bottom right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 16, rect.Y + rect.Height - 16, 32,28),
            new Rectangle(srcx + 48, 96, 32, 28),
            Color.White
            );

        batch.Draw( // left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y + 24, 16, rect.Height-24-16),
            new Rectangle(srcx, 72, 16, 24),
            Color.White
            );
        batch.Draw( // right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 16, rect.Y + 24, 32, rect.Height - 24 - 16),
            new Rectangle(srcx + 48, 72, 32, 24),
            Color.White
            );
        batch.Draw( // top
            PlainMain.Style,
            new Rectangle(rect.X+16, rect.Y, rect.Width - 32, 24),
            new Rectangle(srcx + 16, 48, 1, 24),
            Color.White
            );
        batch.Draw( // bottom
            PlainMain.Style,
            new Rectangle(rect.X + 24, rect.Y + rect.Height - 16, rect.Width - 24-16, 28),
            new Rectangle(srcx + 24, 96, 1, 28),
            Color.White
            );
        batch.Draw( // middle
            PlainMain.Style,
            new Rectangle(rect.X+16, rect.Y+24, rect.Width - 32, rect.Height - 24-16),
            new Rectangle(srcx + 16, 72, 1, 24),
            Color.White
            );


        //batch.DrawString(PlainMain.Font, this.ToString(), new Vector2(rect.X, rect.Y), Color.White);

        return base.Draw(gd, rect, batch);
    }

    public override int FocusIn()
    {
        // hack: should not access unknown parent directly, but for now...
        ((UcWindow)Parent).MoveToTop();
        return base.FocusIn();
    }

    public override int MouseIn(MouseMessage ms)
    {
        Parent.FocusCapture(this);
        base.MouseIn(ms);
        return 0;
    }

    public override int MousePoll(MouseMessage ms)
    {
        return base.MousePoll(ms);
    }

    public void TitleControlCallback(Uc uc, UcTitle.Actions action)
    {
        switch (action)
        {
        case UcTitle.Actions.Collapse:
            Hints.Toggle(HintBits.Floating | HintBits.Collapsed);
            HintBits.SetNeedRepack(this);
            break;
        case UcTitle.Actions.Click:
            if (Hints.IsCollapsed)
            {
                Hints.Set(HintBits.Floating, HintBits.Collapsed);
                HintBits.SetNeedRepack(this);
            }
            break;
        default:
            if (ActionCallback != null)
                ActionCallback(this, action);
            break;
        }
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if ((mode == PositionEnum.Minimum || mode == PositionEnum.Packed) 
        &&  !Hints.IsFloating)
        {
            if (TitleControl == null)
            {
                return new Rectangle(0, 0, margin.X + margin.Width, margin.Y + margin.Height);
            }
            else
            {
                Rectangle rect = TitleControl.PositionQuery(mode);
                TitleControl.PositionPacked = new Rectangle(margin.X, margin.Y, rect.Width, rect.Height);
                rect.X = Position.X;
                rect.Y = Position.Y;
                rect.Width += margin.X + margin.Width;
                rect.Height += margin.Y + margin.Height;
                return rect;
            }
        }
        return base.PositionQuery(mode);
    }

    public override int Repack()
    {
        if (Hints.IsCollapsed)  // special case, minimized
        {
            if (TitleControl != null)
                TitleControl.Repack();
            Position = PositionPacked;
            return 0;
        }
        else // else repack all controls like normal
        {
            return base.Repack();
        }
    }

    public override int Navigate(NavigateMessage ns)
    {
        int status = base.Navigate(ns);
        if (status < 0 && ns.Command == NavigateCommand.Exit)
        {
            if (ActionCallback != null)
                ActionCallback(this, UcTitle.Actions.Close);
            return 0;
        }
        return status;
    }
}

}

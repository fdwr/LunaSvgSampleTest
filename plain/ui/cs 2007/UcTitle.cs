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
    
class UcTitle : Uc
{
    public override string Text
    {
        get { return text; }
        set { text = value; }
    }
    string text;

    /// Sends button clicks on the title bar
    public delegate void ActionDelegate(Uc uc, Actions action);
    public ActionDelegate ActionCallback; // make a multicast delegate instead?? (event)

    // Note that none of these actions are actually
    // done by the title bar - it simply relays the
    // click of the action to it's owner.
    public enum Actions
    {
        None,
        Close, /// close/cancel the window
        Accept, /// accept the settings (okay)
        Collapse, /// collapse group (or minimize window)
        Properties, /// bring up properties dialog, delete this one?
        Menu, /// window menu (if it has one)
        Small, /// make small size (not minimize)
        Help, /// open related help or maybe enter help pointer mode?
        FullScreen, /// take full screen, not the same as maximize (useless on Xbox)
        Large, /// be a large window (maximize)
        Undo, /// reset defaults or undo last action
        Lock,
        Move,
        Size,
        Click, /// when no button was clicked or title bar not grabbed (not received if another is)
        Total,
    }
    [Flags] // this attribute should increment the enum's by *2 each time
	public enum StateFlags {
        First = 1,
        Close = 1 << Actions.Close,
        Accept = 1 << Actions.Accept,
        Collapse = 1 << Actions.Collapse,
        Properties = 1 << Actions.Properties,
        Menu = 1 << Actions.Menu,
        Small = 1 << Actions.Small,
        Help = 1 << Actions.Help,
        FullScreen = 1 << Actions.FullScreen,
        Large = 1 << Actions.Large,
        Undo = 1 << Actions.Undo,
        Lock = 1 << Actions.Lock,
        Move = 1 << Actions.Move,
        Size = 1 << Actions.Size,

        Default = Close,
	};
    StateFlags state;
    public StateFlags State
    {
        get { return state; }
        set { 
            state = value;
            HintBits.SetNeedRepack(this);
        } // check that no other flags should be clobbered?
    }
    static Actions mouseAction = Actions.None;


    public UcTitle(Uc parent, string initialText, ActionDelegate callback)
    {
        Debug.Assert(parent != null);
        Debug.Assert(initialText != null);

        text = initialText;
        ActionCallback = callback;
        
        Rectangle parentRect = parent.Position;
        Position = new Rectangle(8, 8, parentRect.Width - 16, 32); // align to parent

        Hints.Set(HintBits.PackTop | HintBits.NoKeyFocus | Uc.HintBits.PackWide);

        parent.InsertChild(this);
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        Uc.HintBits parentHints = Parent.Hints;
        int srcx
            //= (parentFlags.IsDisabled) ? 400
            = (parentHints.IsKeyFocused) ? 476
            : 444;

        batch.Draw( // left
            PlainMain.Style, 
            new Rectangle(rect.X, rect.Y, 16, rect.Height),
            new Rectangle(srcx, 48,16,32),
            Color.White
            );
        batch.Draw( // right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 16, rect.Y, 16, rect.Height),
            new Rectangle(16+srcx,48,16,32),
            Color.White
            );
        batch.Draw( // middle
            PlainMain.Style,
            new Rectangle(rect.X + 16, rect.Y, rect.Width - 32, rect.Height),
            new Rectangle(16 + srcx, 48, 4, 32),
            Color.White
            );

        
        // draw each title bar icon
        int destx = rect.X + rect.Width - 8 - 16;
        srcx = 508;
        int iconsWidth = 0;
        for (Actions ai = Actions.None + 1; ai <= Actions.Total; ai++)
        {
            // arg... no implicit enum to int makes my code UGLY
            srcx -= 16;
            if ((state & (StateFlags)(1 << (int)ai)) != 0)
            {
                int srcy = (ai == mouseAction && Hints.IsMouseFocused) ? 108 : 92;
                batch.Draw(
                    PlainMain.Style,
                    new Rectangle(destx - iconsWidth, rect.Y + 8, 16, 16),
                    new Rectangle(srcx, srcy, 16, 16),
                    Color.White
                    );
                iconsWidth += 16;
            }
        }

        // center horizontally and vertically
        // *the cast to int is to prevent blurry text
        Vector2 textPos = new Vector2(rect.Width, rect.Height);
        textPos -= PlainMain.Font.MeasureString(text);
        textPos.X -= iconsWidth;
        textPos = new Vector2(rect.X + (int)(textPos.X / 2), rect.Y + (int)(textPos.Y / 2));
        batch.DrawString(PlainMain.Font, text, textPos, Color.White);

        return 0;
        //return base.Draw(gd, rect, batch, font);
    }

    public override int MousePoll(MouseMessage ms)
    {
        if (ms.LeftButton == ButtonRelative.Pressed)
        {
            Actions action = GetHoveredAction(ms);
            if (action != Actions.None)
            {
                mouseAction = action;
            }
            else if (Parent.Hints.IsFloating && Parent.MouseCapture(this) >= 0)
            {
                mouseAction = Actions.Move;
                if (ActionCallback != null)
                    ActionCallback(this, mouseAction);
            }
            else
            {
                if (ActionCallback != null)
                    ActionCallback(this, Actions.Click);
            }
        }
        else if (ms.LeftButton == ButtonRelative.Released)
        {
            Parent.MouseCapture(null);
            if (mouseAction != Actions.None && mouseAction != Actions.Move) {
                if (ActionCallback != null && GetHoveredAction(ms) == mouseAction) {
                    ActionCallback(this, mouseAction);
                }
            }
            mouseAction = Actions.None;
        }
        else if (ms.LeftButton >= ButtonRelative.Down)
        {
            if (mouseAction == Actions.Move
            && (ms.XChange != 0 || ms.YChange != 0))
            {
                Rectangle parentRect = Parent.Position;
                parentRect.X += ms.XChange;
                parentRect.Y += ms.YChange;
                // clip to grandparent's bounds
                if (Parent.Parent != null) {
                    Rectangle grandParentRect = Parent.Parent.Position;
                    grandParentRect.Width -= parentRect.Width;
                    grandParentRect.Height -= parentRect.Height;
                    if (parentRect.X > grandParentRect.Width) parentRect.X = grandParentRect.Width;
                    if (parentRect.Y > grandParentRect.Height) parentRect.Y = grandParentRect.Height;
                }
                if (parentRect.X < 0) parentRect.X = 0;
                if (parentRect.Y < 0) parentRect.Y = 0;
                Parent.Reposition(new Rectangle(parentRect.X, parentRect.Y, int.MinValue, int.MinValue));
            };
        }
        return 0;
    }

    public override int MouseOut(MouseMessage ms)
    {
        mouseAction = Actions.None;
        return 0;
    }

    Actions GetHoveredAction(MouseMessage ms)
    {
        // ugly... hard coded constants :-/
        // check for any button pressed
        Actions ai = Actions.None;
        if (ms.Y >= 8 && ms.Y <= 8 + 16 && ms.X < Position.Width - 8)
        {
            int x = Position.Width - 8 - ms.X;
            // check all buttons that are shown
            for (ai++; ai < Actions.Total; ++ai)
            {
                if ((state & (StateFlags)(1 << (int)ai)) != 0)
                    if ((x -= 16) <= 0) break;
            }
            if (ai >= Actions.Total) ai = Actions.None;
        }
        return ai;
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Minimum) 
        {
            return new Rectangle(0, 0, 0, 0);
        }
        else if (mode == PositionEnum.Packed)
        {
            Vector2 size = PlainMain.Font.MeasureString(text);
            int iconsWidth = 0;
            for (Actions ai = Actions.None + 1; ai <= Actions.Total; ai++)
            {
                // arg... no implicit enum to int makes my code UGLY
                if ((state & (StateFlags)(1 << (int)ai)) != 0)
                    iconsWidth += 16;
            }
            return new Rectangle(0, 0, (int)size.X + 24 + iconsWidth, 32);//(int)size.Y + 8);
        }
        else
        {
            return base.PositionQuery(mode);
        }
    }
}

}

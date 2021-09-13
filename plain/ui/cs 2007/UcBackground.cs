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

class UcBackground : Uc
{
    public UcBackground(Uc parent)
    {
        Hints.Set(HintBits.PackTall | HintBits.PackWide);
        Position = PositionPacked = new Rectangle(0, 0, parent.Position.Width, parent.Position.Height);
        parent.InsertChild(this);
    }

    public override int MousePoll(MouseMessage ms)
    {
        if (ms.LeftButton == ButtonRelative.Pressed)
        {
            Parent.MouseCapture(this);
            Parent.FocusCapture(this);
            return 0;
        }
        else if (ms.RightButton == ButtonRelative.Pressed)
        {
            Parent.FocusCapture(this);
            return 0;
        }
        else if (ms.LeftButton == ButtonRelative.Released)
        {
            Parent.MouseCapture(null);
            return 0;
        }
        return -1;
        //return base.MousePoll(ms);
    }

    public override int MouseIn(MouseMessage ms)
    {
        Parent.FocusCapture(this);
        return 0;
        //return base.MouseIn(ms);
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Packed)
        {
            return new Rectangle(0, 0, Parent.Position.Width, Parent.Position.Height);
        }
        return base.PositionQuery(mode);
    }

    public override int Navigate(NavigateMessage ns)
    {
        switch (ns.Command)
        {
        case NavigateCommand.Down:
        case NavigateCommand.Up:
        case NavigateCommand.Left:
        case NavigateCommand.Right:
            return 0;
        }
        return base.Navigate(ns);
    }
}

}

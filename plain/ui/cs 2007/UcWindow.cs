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

/**
Summary:
    -Generic window/container class to hold user controls (widgets).
    -Containers need not inherit from this, but it is VERY convenient,
     and I recommend avoiding the chunks of code to notify children
     and set child flags right (one justifiable example of not inheriting
     from window would be simple compound objects, like a label and slider
     joined together).
    -Does NOT do any layout of widgets. They simply appear at whatever
     position they are initially set to. Use one of the more intelligent
     ones if you want that.
*/
public class UcWindow : Uc
{
    protected List<Uc> widgets = new List<Uc>();
    protected Uc focusWidget; /// widget with key focus
    protected Uc mouseWidget; /// widget with mouse focus
    protected bool mouseCaptured = false;
    protected int spacing; /// spacing between widgets
    protected Rectangle margin; /// filler around perimeter (in CSS terms, table padding)
    // ! height and width are actually offsets from the right and bottom side

    public delegate Rectangle PackerDelegate(List<Uc> list, Rectangle rect, int spacing, bool queryOnly);
    protected PackerDelegate Packer;


    protected UcWindow()
    {
    }

    public UcWindow(Uc parent, PackerDelegate initialPacker)
    {
        Packer = (initialPacker != null) ? initialPacker : PackerNothing;

        // one of the very few widgets that is allowed to
        // have no parent (null), since the base window is
        // usually used to host the main screen.
        if (parent != null)
            parent.InsertChild(this);
    }

    public override int InsertChild(Uc widget)
    {
        if (widget.Parent != null)
            widget.Parent.DeleteChild(widget); // be sure to delete from other parent
        HintBits.SetNeedRepack(this);
        widget.Parent = this;
        widgets.Add(widget);
        return 0;
    }

    public override int DeleteChild(Uc widget)
    {
        Debug.Assert(widget.Parent == this);

        HintBits.SetNeedRepack(this);

        widget.Parent = null;
        widgets.Remove(widget);
        return 0;
    }

    public override int Destroy()
    {
        for (int i=0; i < widgets.Count; i++)
        {
            Uc child = widgets[i];
            widgets[i] = null; // set to null to prevent the list moving underneath us
            child.Destroy();
        }
        return base.Destroy();
    }

    public override int Predraw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        // if we were doing something fancier here like rendering to a texture,
        // these offsets could be remapped to the texture rather than screen.
        foreach (Uc child in widgets)
        {
            if (child.Hints.IsHidden) continue;
            
            Rectangle childRect = child.Position;
            // never mind this more complex clipping
            //if (childRect.X + childRect.Width  > rect.Width)  childRect.Width  = rect.Width  - childRect.X;
            //if (childRect.Y + childRect.Height > rect.Height) childRect.Height = rect.Height - childRect.Y;
            //if (childRect.X < rect.X) childRect.X = rect.X;
            //if (childRect.Y < rect.Y) childRect.Y = rect.Y;

            // just do basic all or nothing clipping
            if (childRect.X < Position.Width && childRect.Y < Position.Height
            &&  childRect.Width > 0 && childRect.Height > 0)
            {
                childRect.Offset(rect.X, rect.Y);
                child.Predraw(gd, childRect, batch);
            }
        }
        return 0;
    }

    // Because this widget is merely a container,
    // it only draw it's children, and has no visible representation,
    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        // if we were doing something fancier here like rendering to a texture,
        // the rect offsets could be remapped to the texture rather than screen.
        foreach (Uc child in widgets) 
        {
            if (child.Hints.IsHidden) continue;

            Rectangle childRect = child.Position;
            // never mind this more complex clipping
            //if (childRect.X + childRect.Width  > rect.Width)  childRect.Width  = rect.Width  - childRect.X;
            //if (childRect.Y + childRect.Height > rect.Height) childRect.Height = rect.Height - childRect.Y;
            //if (childRect.X < rect.X) childRect.X = rect.X;
            //if (childRect.Y < rect.Y) childRect.Y = rect.Y;

            // just do basic all or nothing clipping
            if (childRect.X < Position.Width && childRect.Y < Position.Height
            && childRect.Width > 0 && childRect.Height > 0)
            {
                childRect.Offset(rect.X, rect.Y);
                child.Draw(gd, childRect, batch);
            }
        }
        return 0;
    }


    #region Input Mouse

    /**
    -Finds mouse widget
    -Adjusts mouse cursor position relative to it
    -Relays message
    */
    int MouseMessageRelay(MouseMessage ms, MouseMessageDelegate mmd)
    {
        Debug.Assert(mouseWidget != null);

        // special case of mouseout where no mouse state is available
        if (ms == null)
        {
            return mmd(ms);
        }

        Point cursor = new Point(ms.X, ms.Y);
            ms.X -= mouseWidget.Position.X; // adjust relative to child
            ms.Y -= mouseWidget.Position.Y;
                int returnValue = mmd(ms);
            ms.Y = cursor.Y; // restore
            ms.X = cursor.X;
        return returnValue;
    }

    bool MouseWidgetSelect(MouseMessage ms)
    {
        // if still within bounds of previous mouse object
        #if false // don't check every control
        if (mouseWidget != null)
        {
            if (mouseWidget.Parent == this)
            {

                if (mouseWidget.Hints.CanGetMouseFocus
                && (mouseCaptured || mouseWidget.Position.Contains(ms.X, ms.Y)))
                {
                    return true;
                }
                else
                {
                    mouseWidget.Hints.Clear(HintBits.MouseFocused);
                    MouseMessageRelay(ms, mouseWidget.MouseOut);
                }
            }
        }
        mouseCaptured = false;

        // find new one
        foreach (Uc child in widgets)
        {
            if (child.Hints.CanGetMouseFocus
            &&  child.Position.Contains(ms.X, ms.Y))
            {
                mouseWidget = child;
                mouseWidget.Hints.Set(HintBits.MouseFocused);
                MouseMessageRelay(ms, mouseWidget.MouseIn);
                return true;
            }
        }
        
        // none found
        mouseWidget = null;
        return false;

        #else // just check every control

        Uc newWidget = null;

        if (mouseCaptured)
        {
            newWidget = mouseWidget;
        }
        else 
        {
            // find new one
            for (int uci = widgets.Count-1; uci >= 0; --uci)
            {
                Uc child = widgets[uci];
                if (child.Hints.CanGetMouseFocus
                && child.Position.Contains(ms.X, ms.Y))
                {
                    newWidget = child;
                    break;
                }
            }
        }

        if (newWidget != mouseWidget) // different
        {
            if (mouseWidget != null)
            {
                mouseWidget.Hints.Clear(HintBits.MouseFocused);
                MouseMessageRelay(ms, mouseWidget.MouseOut);
            }
            mouseWidget = newWidget;
            mouseCaptured = false;
            if (mouseWidget != null)
            {
                mouseWidget.Hints.Set(HintBits.MouseFocused);
                MouseMessageRelay(ms, mouseWidget.MouseIn);
            }
        }
        return (mouseWidget != null);
        #endif
    }

    public override int MousePoll(MouseMessage ms) 
    {
        // just send directly to it
        if (MouseWidgetSelect(ms))
            return MouseMessageRelay(ms,  mouseWidget.MousePoll);
        return -1;
    }
    /*
    public override int MouseMove(MouseMessage ms) 
    {
        if (GetMouseWidget(ms))
            return mouseWidget.MouseMove(ms);
        return -1;
    }
    public override int MousePress(MouseMessage ms) 
    {
        if (GetMouseWidget(ms))
            return mouseWidget.MousePress(ms);
        return -1;
    }
    public override int MouseRelease(MouseMessage ms)
    {
        if (GetMouseWidget(ms))
            return mouseWidget.MouseRelease(ms);
        return -1;
    }
    */
    public override int MouseIn(MouseMessage ms)
    {
        Debug.Assert(mouseWidget == null || (mouseCaptured && mouseWidget != null));
        if (MouseWidgetSelect(ms))
        {
            // in case it did not send a focus in message
            // which will happen when initially switching
            // to a window (not just switching controls within)
            if (!mouseWidget.Hints.IsMouseFocused)
            {
                mouseWidget.Hints.Set(HintBits.MouseFocused);
                mouseWidget.FocusIn();
            }
        }
        return 0;
    }

    public override int MouseOut(MouseMessage ms)
    {
        //if (MouseWidgetSelect(ms))
        mouseCaptured = false;
        if (mouseWidget != null)
        {
            mouseWidget.Hints.Clear(HintBits.MouseFocused);
            MouseMessageRelay(ms, mouseWidget.MouseOut);
            mouseWidget = null;
        }
        //Debug.Assert(mouseWidget == null);
        return 0;
    }

    public override int MouseCapture(Uc widget)
    {
        Debug.Assert(widget == null || widget.Parent == this);
        if (widget != null && !widget.Hints.CanGetMouseFocus)
        {
            return -1;
        }

        if (widget == null) // special case, releasing focus
        {
            mouseCaptured = false;
            if (Parent != null) return Parent.MouseCapture(null);
            return 0;
        }

        mouseCaptured = true;
        if (Hints.IsMouseFocused || Parent == null)
        {
            // if mouse focused already, just switch current widget
            Uc previousWidget = mouseWidget;
            mouseWidget = widget;
            // inform previous control of loss
            if (previousWidget != null && previousWidget != widget)
            {
                MouseMessage ms = new MouseMessage();
                ms.X = ms.Y = int.MinValue;
                previousWidget.Hints.Clear(HintBits.MouseFocused);
                previousWidget.MouseOut(ms);
            }
            // unlike key focus, do NOT send message
            // must wait until next mouse message
        }
        // chain request up
        mouseWidget = widget;
        if (Parent != null) Parent.MouseCapture(this);
        return 0;
    }

    #endregion


    #region Input focus

    bool FocusWidgetSelect()//KeyStateRelative ks)
    {
        if (focusWidget != null)
        {
            if (focusWidget.Parent == this)
            {
                if (focusWidget.Hints.CanGetKeyFocus)
                {
                    return true;
                }
                else
                {
                    focusWidget.Hints.Clear(HintBits.KeyFocused);
                    if (Hints.IsKeyFocused) focusWidget.FocusOut();
                }
            }
        }

        // find another one
        foreach (Uc child in widgets)
        {
            if (child.Hints.CanGetKeyFocus)
            {
                focusWidget = child;
                if (Hints.IsKeyFocused)
                {
                    focusWidget.Hints.Set(HintBits.KeyFocused);
                    focusWidget.FocusIn();
                }
                return true;
            }
        }

        // none found
        focusWidget = null;
        return false;
    }

    public override int FocusIn()
    {
        if (FocusWidgetSelect())
        {
            // in case it did not send a focus in message
            // which will happen when initially switching
            // to a window (not just switching controls within)
            if (!focusWidget.Hints.IsKeyFocused)
            {
                focusWidget.Hints.Set(HintBits.KeyFocused);
                focusWidget.FocusIn();
            }
        }
        return 0;
        //return base.FocusIn();
    }

    public override int FocusOut()
    {
        if (focusWidget != null && focusWidget.Parent == this)
        {
            focusWidget.Hints.Clear(HintBits.KeyFocused);
            focusWidget.FocusOut();
        }
        return 0;
    }

    public override int FocusCapture(Uc widget)
    {
        Debug.Assert(widget != null); // unlike the mouse, null is never allowed
        Debug.Assert(widget.Parent == this);
        if (!widget.Hints.CanGetKeyFocus)
            return -1;

        if (Hints.IsKeyFocused || Parent == null)
        {
            // if key focused already, just switch current widget
            if (widget != focusWidget) // if same, don't bother
            {
                Uc previousWidget = focusWidget;
                focusWidget = widget;
                // inform previous control of loss
                if (previousWidget != null) {
                    previousWidget.Hints.Clear(HintBits.KeyFocused);
                    previousWidget.FocusOut();
                }
                // inform new control of gain
                widget.Hints.Set(HintBits.KeyFocused);
                widget.FocusIn();
            }
        }
        else
        {
            // chain request up
            focusWidget = widget;
            return Parent.FocusCapture(this);
        }
        return 0;
    }

    /// Find next control that can receive key focus,
    /// given previous/next/first/last.
    Uc FindNextKeyFocus(NavigateCommand nc)
    {
        if (widgets.Count <= 0) return null;

        // determine direction to search based on navigation command
        // whether forward or backward, starting from the current
        // focus control or one of the ends...
        int uci, step=1;
        switch (nc) {
        case NavigateCommand.First:
            //step = 1
            uci = 0;
            break;
        case NavigateCommand.Last:
            step = -1;
            uci = widgets.Count-1;
            break;
        case NavigateCommand.Prior:
            step = -1;
            goto case NavigateCommand.Next;
        case NavigateCommand.Next:
        default:
            //step = 1
            uci = widgets.IndexOf(focusWidget);
            uci += step;
            break;
        }

        // search for next candidate control
        for (int i = widgets.Count; i > 0; i--, uci += step)
        {
            // wrap around ends if necessary
            if ((uint)uci >= widgets.Count)
            {
                // only wrap if a complete window, not embedded in a larger one
                if (!Hints.IsFloating) break;
                if (uci < 0) uci = widgets.Count - 1;
                else uci = 0;
            }
            Uc child = widgets[uci];
            if (child.Hints.CanGetKeyFocus
            &&  child.HintsQuery(HintBits.NoKeyFocus).CanGetKeyFocus)
            {
                return child;
            }
        }
        return null;
    }
    #endregion


    #region Input keyboard and gamepad

    public override int KeyPoll(KeyboardMessage ks)
    {
        if (FocusWidgetSelect())
            return focusWidget.KeyPoll(ks);
        return -1;
    }
    public override int KeyPress(KeyboardMessage ks)
    {
        if (FocusWidgetSelect())
            return focusWidget.KeyPress(ks);
        return -1;
    }
    public override int KeyRelease(KeyboardMessage ks)
    {
        if (FocusWidgetSelect())
            return focusWidget.KeyRelease(ks);
        return -1;
    }


    public override int GamepadPoll(GamePadMessage gs)
    {
        if (FocusWidgetSelect())
            return focusWidget.GamepadPoll(gs);
        return -1;
    }


    public override int Navigate(NavigateMessage ns)
    {
        if (FocusWidgetSelect()) {
            // chain along to child in case it wants the message
            if (Hints.IsKeyFocused)
            {
                int result = focusWidget.Navigate(ns);
                if (result >= 0)
                    return result; // control handled it
            }

            // handle it here if control ignored message
            Uc nextControl = null;

            NavigateCommand childCommand = 0;
            switch (ns.Command)
            {
            case NavigateCommand.First:
                nextControl = FindNextKeyFocus(NavigateCommand.First);
                childCommand = NavigateCommand.First;
                break;
            case NavigateCommand.Last:
                nextControl = FindNextKeyFocus(NavigateCommand.Last);
                childCommand = NavigateCommand.Last;
                break;
            case NavigateCommand.Right:
            case NavigateCommand.Down:
            case NavigateCommand.Next:
                nextControl = FindNextKeyFocus(NavigateCommand.Next);
                childCommand = NavigateCommand.First;
                break;
            case NavigateCommand.Left:
            case NavigateCommand.Up:
            case NavigateCommand.Prior:
                nextControl = FindNextKeyFocus(NavigateCommand.Prior);
                childCommand = NavigateCommand.Last;
                break;
            }

            if (nextControl != null)
            { // if null, reached end of list or found no control
                // push previous command and restore later
                NavigateCommand prevCommand = ns.Command; ns.Command = childCommand;
                    nextControl.Navigate(ns);
                ns.Command = prevCommand;
                if (focusWidget != nextControl) FocusCapture(nextControl);
                return 0;
            }
        }
        return -1;
        //return base.Navigate();
    }

    #endregion


    public int MoveToTop() // temp function
    {
        // hmm, cheap hack for now
        // move widget to front of list to put on top
        widgets.Remove(focusWidget);
        widgets.Insert(widgets.Count, focusWidget);
        return 0;
    }


    #region Arrangement algorithms
    /*
    All are declared as static delegates
    So that you don't need pointless temporary interfaces (ala Java)
    or multiple different packer types (ala Fox)
    or write all the code yourself (ala Win32).

    You should call root.PositionQuery(Uc.PositionEnum.Packed)
    before calling root.Repack() so that PositionPacked is
    recursively cached.
    */

    /**
    Summary:
        Do nothing.

    Parameters:
        list - child widgets of window
        rect - boundary to confine packing to
        spacing - space between adjacent controls
        queryOnly - merely calculate the optimal arrangement and size
    */
    static public Rectangle PackerNothing(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        foreach (Uc child in list)
        {
            child.Repack();
            child.Hints.Clear(HintBits.RepackNeeded);
        }
        return rect;
    }

    /**
    Summary:
        Pack sequentially into grid, wrapping if necessary

    Parameters:
        list - child widgets of window
        rect - boundary to confine packing to (x&y contain offset from margin, height&width exclude margin)
        spacing - space between adjacent controls
        queryOnly - merely calculate the optimal arrangement and size
        wrap - number of rows or columns
        vertical - pack vertically rather than horizontally

    Returns:
        The packed rectangle dimensions.
    
    Notes:
        To use a common arrangement (single column, dual column, single row),
        just use the adapter functions. Otherwise you need to specify all the
        parameters yourself with a mini-delegate:

        UcWindow uc = new UcWindowFloating(root,
                delegate(List<Uc> list, Rectangle rect, int spacing, bool queryOnly) {
                    return UcWindow.PackGrid(list, rect, spacing, queryOnly, 3, true);
                }
            );

    */
    static public Rectangle PackerGrid(List<Uc> list, Rectangle rect, int spacing, bool queryOnly, int wrap, bool vertical)
    {
        Debug.Assert(wrap >= 0);
        //Debug.Print("PackGrid q={0} lc={1}", queryOnly, list.Count);

        if (wrap <= 0 || wrap > list.Count) wrap = list.Count;
        if (wrap == 0) return PositionZero; // no children
        
        int cols = wrap;
        int rows = (list.Count + wrap - 1) / wrap;
        if (vertical) {
            int temp = cols; cols = rows; rows = temp;
        }
        Rectangle[] sizes = new Rectangle[(rows > cols) ? rows : cols];

        Rectangle resultRect;

        // determine maximum size for each row
        int col = 0, row = 0;
        foreach (Uc child in list)
        {
            int size;
            if (child.Hints.IsVisible)
            {
                if (child.Hints.IsPackWidth)
                    size = child.Position.Width;
                else
                    size = child.PositionPacked.Width;
                if (size > sizes[col].Width)
                    sizes[col].Width = size;

                if (child.Hints.IsPackHeight)
                    size = child.Position.Height;
                else
                    size = child.PositionPacked.Height;
                if (size > sizes[row].Height)
                    sizes[row].Height = size;
            }

            //Debug.Print(child.ToString() + " w={0} h={1} parent={2}", sizes[col].Width, sizes[row].Height, child.Parent.ToString());

            if (vertical) {
                if (++row >= wrap) { row = 0; col++; }
            }
            else {
                if (++col >= wrap) { col = 0; row++; }
            }
        }

        // sum all heights and widths for top and left offsets
        // collapse hidden rows by checking the size before adding spacing
        for (int i = 1; i < cols; i++)
            sizes[i].X = sizes[i-1].X + sizes[i - 1].Width
                + ((sizes[i - 1].Width > 0)  ? spacing : 0);
        for (int i = 1; i < rows; i++)
            sizes[i].Y = sizes[i-1].Y + sizes[i - 1].Height
                + ((sizes[i - 1].Height > 0) ? spacing : 0);

        resultRect =
            new Rectangle(
                0,
                0,
                sizes[cols - 1].Left + sizes[cols - 1].Width,
                sizes[rows - 1].Top + sizes[rows - 1].Height
                );

        if (queryOnly)
            return resultRect;

        // allot additional space on last row/col if allowed
        int dif;
        if ((dif = rect.Width - resultRect.Width) > 0) {
            resultRect.Width += dif;
            sizes[cols - 1].Width += dif;
        }
        if ((dif = rect.Height - resultRect.Height) > 0)
        {
            resultRect.Height += dif;
            sizes[rows - 1].Height += dif;
        }


        row = col = 0;
        foreach (Uc child in list)
        {
            // todo: constrain children to given rect

            // calculate child rect based on packing hints
            // and current row/col it fits into
            Rectangle childRect = new Rectangle(
                sizes[col].Left + rect.X, 
                sizes[row].Top + rect.Y,
                child.PositionPacked.Width, 
                child.PositionPacked.Height);
            HintBits flags = child.Hints;
            if (flags.IsPackWidth)       childRect.Width = child.Position.Width;
            if (flags.IsPackHeight)      childRect.Height = child.Position.Height;
            
            if (flags.IsPackWide)        childRect.Width = sizes[col].Width;
            else if (flags.IsPackMidCol) childRect.X += (sizes[col].Width - childRect.Width) / 2;
            else if (flags.IsPackRight)  childRect.X += sizes[col].Width - childRect.Width;
            
            if (flags.IsPackTall)        childRect.Height = sizes[row].Height;
            else if (flags.IsPackMidRow) childRect.Y += (sizes[row].Height - childRect.Height) / 2;
            else if (flags.IsPackBottom) childRect.Y += sizes[row].Height - childRect.Height;

            child.PositionPacked = childRect;
            child.Repack();
            //child.Position = childRect; // hack: dirty direct assignment without notifying child
            child.Hints.Clear(HintBits.RepackNeeded);
            
            if (vertical) {
                if (++row >= wrap) { row = 0; col++; }
            }
            else {
                if (++col >= wrap) { col = 0; row++; }
            }
        }

        return resultRect;
    }

    static public Rectangle PackerCol(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        return PackerGrid(list, rect, spacing, queryOnly, int.MaxValue, true);
    }
    static public Rectangle PackerRow(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        return PackerGrid(list, rect, spacing, queryOnly, int.MaxValue, false);
    }
    // special case, since dual column is so common
    // otherwise you need to declare a delegate
    static public Rectangle PackerDualCol(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        return PackerGrid(list, rect, spacing, queryOnly, 2, false);
    }

    /**
    Summary:
        Pack from outside edges inward, receding rectangle.
        Useful for main windows with title and status bars

    Parameters:
        list - child widgets of window
        rect - boundary to confine packing to
        spacing - space between adjacent controls
        queryOnly - merely calculate the optimal arrangement and size
    */
    static public Rectangle PackerInward(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        //Rectangle innerRect;
        // todo: implement PackInward
        return PositionZero;
    }

    /**
    Summary:
        Mostly useless, but might be good for toolbars?
        Simply crams controls left to right, top to bottom

    Parameters:
        list - child widgets of window
        rect - boundary to confine packing to
        spacing - space between adjacent controls
        queryOnly - merely calculate the optimal arrangement and size
        vertical - pack vertically rather than horizontally
    */
    static public Rectangle PackerFlow(List<Uc> list, Rectangle rect, int spacing, bool queryOnly, bool vertical)
    {
        // todo: implement PackFlow
        return PositionZero;
    }
    static public Rectangle PackerFlowVert(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        return PackerFlow(list, rect, spacing, queryOnly, true);
    }
    static public Rectangle PackerFlowHorz(List<Uc> list, Rectangle rect, int spacing, bool queryOnly)
    {
        return PackerFlow(list, rect, spacing, queryOnly, false);
    }

    public override int Repack()
    {
        Position = PositionPacked;
        Rectangle innerRect = new Rectangle(
            margin.X,
            margin.Y,
            Position.Width - margin.Width - margin.X,
            Position.Height - margin.Height - margin.Y);
        Packer(widgets, innerRect, spacing, false);
        return 0;
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        Debug.Assert(Packer != null);

        if (mode == PositionEnum.Packed)
        {
            // cache optimal positions for all children
            foreach (Uc child in widgets)
            {
                child.PositionPacked = child.PositionQuery(PositionEnum.Packed);
            }
            // test pack all items (does not move or resize anything yet)
            // simply caches PositionPacked
            Rectangle rect = Packer(widgets, 
                new Rectangle(
                    margin.X,
                    margin.Y,
                    Position.Width - margin.Width - margin.X,
                    Position.Height - margin.Height - margin.Y),
                spacing,
                true);
            
            rect.X = Position.X;
            rect.Y = Position.Y;
            rect.Width  += margin.Width  + margin.X;
            rect.Height += margin.Height + margin.Y;
            
            return rect;
        }
        
        return base.PositionQuery(mode);
    }

    #endregion

    public override HintBits HintsQuery(uint test)
    {
        HintBits returnHints = Hints;
        if ((test & HintBits.NoKeyFocus) != 0
        &&  !Hints.IsFloating // always allow focus if floating
            )
        {
            // If this window has no immediate children
            // that can receive focus, or the active child
            // currently has nothing that can receive
            // focus (maybe they are all labels),
            // flag as not being able to get keyfocus.
            if (!FocusWidgetSelect()
            ||  !focusWidget.HintsQuery(HintBits.NoKeyFocus).CanGetKeyFocus)
                returnHints.Set(HintBits.NoKeyFocus);
        }
        return returnHints;
    }
}


}//endnamespace

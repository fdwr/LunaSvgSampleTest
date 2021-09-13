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
    Value slider that supports single scalar value
    or ranges (low and high value). Limits are
    arbitrary (not zero fixed like many scroll bars).
*/
class UcSlider : Uc
{
    public override float Value
    {
        get { return Range.X; }
        set
        {
            Range.X = MathHelper.Min(MathHelper.Max(value, Limits.X), Limits.Y);
            Range.Y = float.NaN;
        }
    }
    public override int ValueInt
    {
        get { return (int)Range.X; }
        set {
            Range.X = MathHelper.Min(MathHelper.Max(value, Limits.X), Limits.Y);
            Range.Y = float.NaN;
        }
    }
    public Vector2 Range; // current low-high range; the high value (Y) will be NAN for single scalar values
    public Vector2 Limits;
    public float Step;

    public override string Text
    {
        get { return text; }
        set { text = value; }
    }
    string text;

    Uc textControl;
    public Uc TextControl
    {
        get { return textControl; }
        set
        {
            textControl = TextControl;
            FormatText();
        }
    }

    public TextureRectangle Image;

    /// Sends the current value of the button (pressed/unpressed)
    public delegate void ActionDelegate(UcSlider uc, Vector2 range);
    public ActionDelegate ActionCallback; // make a multicast delegate instead?? (event)

    public enum Actions
    {
        None,
        SetLow, /// set range low
        SetHigh, /// set range high
        SetRange, /// middle region clicked, set both low/high range
        IncreaseRange, /// left arrow clicked, shift range (increase both low/high)
        DecreaseRange, /// right arrow clicked, shift range (decrease both low/high)
        Min, /// align range to minimum
        Max, /// align range to maximum
        WidenRange, /// decrease distance between low and high
        NarrowRange, /// increase distance between low and high
        Total,
    }
    protected static Actions keyAction;
    protected static Actions gamepadAction;
    protected static Actions mouseAction;
    protected static int mouseClickOffset;

    [Flags] // this attribute should increment the enum's by *2 each time
    public enum StateFlags
    {
        None = 0,
        SetLow = 1 << Actions.SetLow,
        SetHigh = 1 << Actions.SetHigh,
        SetRange = 1 << Actions.SetRange,
        IncreaseRange = 1 << Actions.IncreaseRange,
        DecreaseRange = 1 << Actions.DecreaseRange,
        Min = 1 << Actions.Min, /// align range to minimum
        Max = 1 << Actions.Max, /// align range to maximum
        WidenRange = 1 << Actions.WidenRange, /// decrease distance between low and high
        NarrowRange = 1 << Actions.NarrowRange, /// increase distance between low and high
    };


    public UcSlider(Uc parent, float initialValue, Vector2 initialLimits)
        : this(parent, initialValue, initialLimits, new TextureRectangle(), null, null, null)
    { }

    public UcSlider(Uc parent, Vector2 initialRange, Vector2 initialLimits)
        : this(parent, initialRange, initialLimits, new TextureRectangle(), null, null, null)
    { }

    public UcSlider(Uc parent, float initialValue, Vector2 initialLimits, TextureRectangle initialImage, string initialText, Uc initialTextControl, ActionDelegate callback)
    : this( // chain onto ranged version
        parent,
        new Vector2(initialValue, float.NaN), 
        initialLimits, 
        initialImage, 
        (initialText != null) ? initialText : "{0}", 
        initialTextControl, 
        callback)
    {
    }

    public UcSlider(Uc parent, Vector2 initialRange, Vector2 initialLimits, TextureRectangle initialImage, string initialText, Uc initialTextControl, ActionDelegate callback)
    {
        //Hints.Set(HintBits.PackHorizontal);
        text = (initialText != null) ? initialText : "{0}:{1}"; // just display range
        Range = initialRange;
        Limits = initialLimits;
        Step = (Limits.Y - Limits.X) / 100;
        //ActionCallback = (callback != null) ? callback : ActionCallbackFloatDummy;
        ActionCallback = callback;
        textControl = initialTextControl;
        Image = initialImage;
        if (Image.texture == null)
        {
            Image.texture = PlainMain.Style;
            Image.rectangle = new Rectangle(328, 52+1, 32, 1);
        }

        Position = PositionPacked = new Rectangle(0, 0, 280, 24);
        parent.InsertChild(this);

        FormatText();  // format text display now?
    }

    public override int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch batch)
    {
        // combine actions of multiple inputs
        // hmm, cleaner way?
        StateFlags state = 0;
        if (Hints.IsMouseFocused) state |= (StateFlags)(1 << (int)mouseAction);
        if (Hints.IsKeyFocused)
        {
            state |= (StateFlags)(1 << (int)keyAction | 1 << (int)gamepadAction);
        }

        Color color = (Hints.IsDisabled) ? new Color(255, 255, 255, 128) : Color.White;

        //if (Hints.IsPackVertical)
        //{
        //    // todo: slider draw vertical
        //}
        //else 

        int srcx =
            // (Hints.IsDisabled) ? 36 :
            // ((state & StateFlags.Down) != 0) ? 108
             (Hints.IsKeyFocused) ? 216
            : 160;

        batch.Draw( // left
            PlainMain.Style,
            new Rectangle(rect.X, rect.Y, 24, rect.Height),
            new Rectangle(((state & StateFlags.DecreaseRange) != 0) ? 272 : srcx,52,24,28),
            color
            );

        batch.Draw( // right
            PlainMain.Style,
            new Rectangle(rect.X + rect.Width - 24, rect.Y, 24, rect.Height),
            new Rectangle(28 + (((state & StateFlags.IncreaseRange) != 0) ? 272 : srcx), 52, 24, 28),
            color
            );

        batch.Draw( // middle
            PlainMain.Style,
            new Rectangle(rect.X + 24, rect.Y, rect.Width - 24-24, rect.Height),
            new Rectangle(24 + srcx + 2, 52, 1, 28),
            color
            );

        // calculate low and high range arrows
        int barWidth = rect.Width - 24 - 24,
            handleWidth = 0,
            handleOffset;
        if (Limits.Y - Limits.X == 0)
        {
            handleWidth = barWidth;
            handleOffset = 0;
        } 
        else
        {
            double lowFraction = (Range.X-Limits.X) / (Limits.Y - Limits.X);
            handleOffset = (int)(barWidth * lowFraction);
            if (!float.IsNaN(Range.Y)) {
                double highFraction = (Range.Y-Limits.X) / (Limits.Y - Limits.X);
                handleWidth = (int)(barWidth * highFraction) - handleOffset;
            }
        }

        if (Image.texture != null)
        {
            batch.Draw( // texture
                Image.texture,
                new Rectangle(rect.X + 24, rect.Y+2, rect.Width - 24-24, rect.Height-2-2),
                Image.rectangle,
                new Color(255,255,255,192)
            );
        }

        // draw low/high range arrows
        srcx = ((state & (StateFlags.SetLow | StateFlags.SetRange | StateFlags.WidenRange | StateFlags.NarrowRange)) != 0) ? 408 : 384;
        batch.Draw( // low (pointing up)
            PlainMain.Style,
            new Rectangle(rect.X + 24 + handleOffset - 12, rect.Y + rect.Height-16 + 4, 24, 16),
            new Rectangle(srcx, 0, 24, 16),
            color
            );
        srcx = ((state & (StateFlags.SetHigh | StateFlags.SetRange | StateFlags.WidenRange | StateFlags.NarrowRange)) != 0) ? 408 : 384;
        batch.Draw( // low (pointing up)
            PlainMain.Style,
            new Rectangle(rect.X + 24 + handleOffset + handleWidth - 12, rect.Y - 4, 24, 16),
            new Rectangle(srcx, 16, 24, 16),
            color
            );

        return 0;
        //return base.Draw(gd, rect, batch, font);
    }

    void FormatText()
    {
        if (textControl != null)
        {
            textControl.Text = string.Format(text, Range.X, Range.Y);
        }
    }

    public override int MousePoll(MouseMessage ms)
    {
        if (ms.LeftButton == ButtonRelative.Pressed)
        {
            Actions action = GetHoveredAction(ms);
            if (Parent.MouseCapture(this) >= 0) {
                mouseAction = action;
                mouseClickOffset = -24;//(int)((length - 24 - 24) * Range.X / (Limits.Y - Limits.X));
                if (action == Actions.SetRange)
                {
                    int length;
                    if (Hints.IsPackVertical)
                    {
                        length = Position.Height;
                        mouseClickOffset = -ms.Y;
                    }
                    else
                    {
                        length = Position.Width;
                        mouseClickOffset = -ms.X;
                    }
                    mouseClickOffset += (int)((length - 24 - 24) * (Range.X) / (Limits.Y - Limits.X));
                }
            };
        }
        else if (ms.LeftButton == ButtonRelative.Released)
        {
            mouseAction = Actions.None;
            Parent.MouseCapture(null);
        }
        if (ms.LeftButton >= ButtonRelative.Down)
        {
            int offset = (Hints.IsPackVertical) 
                ? (ms.Y + mouseClickOffset)
                : (ms.X + mouseClickOffset);
            float value = offset * (Limits.Y - Limits.X) / (Position.Width - 24 - 24);
            DoAction(mouseAction, value, false);
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
        mouseAction = Actions.None;
        return 0;
    }

    Actions GetHoveredAction(MouseMessage ms)
    {
        // ugly... hard coded constants :-/
        // check for any button pressed
        int x, y, width, height;
        
        // flip orientation
        if (Hints.IsPackVertical) {
            y = ms.X; x = ms.Y; width = Position.Height; height = Position.Width;
        }
        else {
            x = ms.X; y = ms.Y; width = Position.Width; height = Position.Height;
        }

        Actions ai;// = Actions.None;
        if (x < 24) ai = Actions.DecreaseRange;
        else if (x >= width - 24) ai = Actions.IncreaseRange;
        else if (y < 5) ai = Actions.SetHigh;
        else if (y >= height - 5) ai = Actions.SetLow;
        else ai = Actions.SetRange;
        return ai;
    }

    public override int KeyPoll(KeyboardMessage ks)
    {
        keyAction = Actions.None;
        //if (ks.ButtonCode == Keys.Space) 
        //    Activate(true);
        if (Hints.IsPackVertical)
        {
            if (ks.IsKeyDown(Keys.Up))    keyAction = Actions.IncreaseRange;
            if (ks.IsKeyDown(Keys.Down))  keyAction = Actions.DecreaseRange;
        }
        else
        {
            if (ks.IsKeyDown(Keys.Right)) keyAction = Actions.IncreaseRange;
            if (ks.IsKeyDown(Keys.Left))  keyAction = Actions.DecreaseRange;
        }
        if (ks.IsKeyDown(Keys.Home))      keyAction = Actions.Min;
        if (ks.IsKeyDown(Keys.End))       keyAction = Actions.Max;
        if (ks.IsKeyDown(Keys.Subtract))  keyAction = Actions.NarrowRange;
        if (ks.IsKeyDown(Keys.Add))       keyAction = Actions.WidenRange;
        DoAction(keyAction, 0, false);

        return (keyAction != Actions.None) ? 0 : -1;
    }

    public override int GamepadPoll(GamePadMessage gs)
    {
        gamepadAction = Actions.None;
        float speed = (Hints.IsPackVertical) ? gs.ThumbStickLeft.Y : gs.ThumbStickLeft.X;
        
        if (gs.ShoulderLeft >= ButtonRelative.Down || gs.TriggerLeft > .75)
        {
            if (gs.ShoulderRight >= ButtonRelative.Down || gs.TriggerRight > .75)
                gamepadAction = Actions.WidenRange;
            else
                gamepadAction = Actions.SetLow;
        }
        else if (gs.ShoulderRight >= ButtonRelative.Down || gs.TriggerRight > .75)
        {
                gamepadAction = Actions.SetHigh;
        }

        if (speed != 0f)
        {
            // if neither LB or RB was held
            if (gamepadAction == Actions.None) {
                gamepadAction = (speed > 0) 
                    ? Actions.IncreaseRange
                    : Actions.DecreaseRange;
                speed = Math.Abs(speed);
            }
            DoAction(gamepadAction, speed, true);
        }

        return 0;
    }

    void DoAction(Actions action, float value, bool relative)
    {
        Vector2 newRange = Range;
        float span = (float.IsNaN(Range.Y)) ? 0 : (Range.Y - Range.X);
        bool clampSeparately = false; // clamp the low & high separately, ignoring their span

        switch (action)
        {
        case Actions.None:
            return;
        case Actions.DecreaseRange:
            if (!relative) value = Step;
            newRange.X -= value;
            newRange.Y -= value;
            break;
        case Actions.IncreaseRange:
            if (!relative) value = Step;
            newRange.X += value;
            newRange.Y += value;
            break;

        case Actions.SetLow:
            if (relative) newRange.X += value;
            else          newRange.X = value;
            clampSeparately = true;
            break;
        case Actions.SetHigh:
            if (relative) newRange.Y += value;
            else          newRange.Y = value;
            clampSeparately = true;
            break;
        
        case Actions.Min:
            newRange.X = Limits.X;
            newRange.Y = newRange.X + span;
            break;
        case Actions.Max:
            newRange.Y = Limits.Y;
            newRange.X = newRange.Y - span;
            break;

        case Actions.SetRange:
            if (relative) newRange.X += value;
            else          newRange.X = value;
            newRange.Y =  newRange.X + span;
            break;
        
        case Actions.WidenRange:
            if (!relative) value = Step;
            if ((value < 0 && newRange.X == newRange.Y) || float.IsNaN(newRange.Y))
                return; // *** otherwise funky sliding occurs
            newRange.X -= value;
            newRange.Y += value;
            clampSeparately = true;
            break;
        case Actions.NarrowRange:
            if (newRange.X == newRange.Y || float.IsNaN(newRange.Y))
                return; // *** otherwise funky sliding occurs
            if (!relative) value = Step;
            newRange.X += value;
            newRange.Y -= value;
            clampSeparately = true;
            break;
        }

        if (float.IsNaN(Range.Y)) // simpler test for single scalar value
        {
            if (newRange.X > Limits.Y) newRange.X = Limits.Y;
            else if (newRange.X < Limits.X) newRange.X = Limits.X;
            newRange.Y = float.NaN;
        }
        else // more complex tests for two sided ranges :-/ can it be simplified?
        {
            // don't ever allow min > max
            if (newRange.X > newRange.Y)
            {
                if (newRange.X == Range.X) // max was moved below min
                    newRange.X = newRange.Y;
                else // min was moved above max
                    newRange.Y = newRange.X;
            }

            // clamp ranges in case they went past limits
            if (newRange.Y > Limits.Y)
            {
                newRange.Y = Limits.Y;
                if (!clampSeparately)
                    newRange.X = newRange.Y - span;
            }
            if (newRange.X < Limits.X)
            {
                newRange.X = Limits.X;
                if (!clampSeparately)
                    newRange.Y = newRange.X + span;
            }

            // now clamp for opposite possibility
            if (newRange.X > Limits.Y) newRange.X = Limits.Y;
            if (newRange.Y < Limits.X) newRange.Y = Limits.X;
        }

        // actually set the value now
        if (Range != newRange) {
            Range = newRange;
            if (ActionCallback != null)
                ActionCallback(this, Range);
            FormatText();
        }
    }

    public override Rectangle PositionQuery(PositionEnum mode)
    {
        if (mode == PositionEnum.Minimum || mode == PositionEnum.Packed) 
        {
            if (Hints.IsPackVertical)
                return new Rectangle(0, 0, 28, 280);
            else
                return new Rectangle(0, 0, 280, 28);
        }
        return base.PositionQuery(mode);
    }

    public override int Navigate(NavigateMessage ns)
    {
        switch (ns.Command)
        {
        case NavigateCommand.Left:
        case NavigateCommand.Right:
            if (!Hints.IsPackVertical) return 0;
            break;
        case NavigateCommand.Up:
        case NavigateCommand.Down:
            if (Hints.IsPackVertical) return 0;
            break;
        }
        return base.Navigate(ns);
    }
}

}

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

public enum Message {
    Nop,
    Draw,
    Predraw,
    FocusIn,
    FocusOut,
    FocusCapture, /// want focus
    Navigate,
    MousePoll,
    //MouseMove,
    //MousePress,
    //MouseRelease,
    MouseIn,
    MouseOut,
    MouseCapture, /// grab or release exclusive mouse focus
    KeyPoll,
    KeyPress,
    KeyRelease,
    GamepadPoll,
    //Reposition, /// set position (offset and size)
    //GamepadPress, // arg, too many buttons to test
    //GamepadRelease,
    Total,
}

////////////////////////////////////////////////////////////////////////////////
#region Input definitions

public delegate int KeyboardMessageDelegate(KeyboardMessage ks);
public delegate int GamePadDelegate(GamePadMessage gs);
public delegate int MouseMessageDelegate(MouseMessage ms);

/** 
Summary:
    -Identifies the state of a mouse, keyboard, or gamepad button.
    -Unlike the XNA ButtonState enum, Pressed means the button was actually PRESSED,
     not just that it is currently down.
*/
[Flags] // allow ORs without compiler whining (but why doesn't left shift work?)
public enum ButtonRelative : byte
{
    Up = 0, // currently up, whether for a while or just released
    Changed = 1, // either transitioned from down to up, or up to down
    Down = 2, // currently held down, whether for a while or just pressed
    Released = Changed | Up, // was just released
    Pressed = Changed | Down, // was just pressed
}

// almost exactly like XNA's MouseState, but holds relative difference.
public class MouseMessage
{
    //public Message Message;
    //public enum ButtonCodes { LeftButton, MiddleButton, RightButton, XButton1, XButton2, ScrollWheel }
    //public ButtonCodes ButtonCode; // key last pressed or released, only applicable within a key press/release message

    public ButtonRelative LeftButton;
    public ButtonRelative MiddleButton;
    public ButtonRelative RightButton;
    public ButtonRelative XButton1;
    public ButtonRelative XButton2;
    public int ScrollWheelValue;
    public int ScrollWheelChange;
    public int X; // offset within window, not absolute cursor position
    public int Y;
    public int XChange; // relative change since last time
    public int YChange;

    public void Update(ref MouseState state, ref MouseState prestate)
    {
        Debug.Assert((int)ButtonState.Pressed == 1); // ensure bit math still valid, in case they change it

        LeftButton = PlainUtils.GetButtonState(state.LeftButton, prestate.LeftButton);
        MiddleButton = PlainUtils.GetButtonState(state.MiddleButton, prestate.MiddleButton);
        RightButton = PlainUtils.GetButtonState(state.RightButton, prestate.RightButton);
        XButton1 = PlainUtils.GetButtonState(state.XButton1, prestate.XButton1);
        XButton2 = PlainUtils.GetButtonState(state.XButton2, prestate.XButton2);
        ScrollWheelChange = state.ScrollWheelValue - prestate.ScrollWheelValue;
        ScrollWheelValue = state.ScrollWheelValue;
        X = state.X;
        Y = state.Y;
        XChange = state.X - prestate.X;
        YChange = state.Y - prestate.Y;
    }
}

// almost exactly like XNA's KeyboardState, but holds relative difference.
public class KeyboardMessage
{
    public Message Message; // press or release
    public Keys ButtonCode; // key last pressed or released, only applicable within a key press/release message

    // "Cannot have instance field initializers in structs" - broken C#, D rules
    //public ButtonRelative[] keyArray = new ButtonRelative[256];
    public ButtonRelative[] keyArray;


    public ButtonRelative this[Keys key]
    { 
        get { return keyArray[(int)key]; }
        //set { keyArray[key] = (ButtonRelative)value; }
    }

    // "Structs cannot contain explicit parameterless constructors" - broken C#, D rules
    public KeyboardMessage()
    {
        keyArray = new ButtonRelative[256];
    }

    //public Keys[] GetPressedKeys();

    public bool IsKeyDown(Keys key) {
        return (keyArray[(int)key] & ButtonRelative.Down) != 0;
    }
    public bool IsKeyUp(Keys key) {
        return (keyArray[(int)key] & ButtonRelative.Down) == 0;
    }
    public bool IsKeyPressed(Keys key) {
        return (keyArray[(int)key] == ButtonRelative.Pressed);
    }
    public bool IsKeyReleased(Keys key) {
        return (keyArray[(int)key] == ButtonRelative.Released);
    }

    public void Update(ref KeyboardState state, ref KeyboardState prestate)
    {
        Debug.Assert((int)KeyState.Down == 1); // ensure bit math still valid, in case they change it

        for (uint ki = 0; ki < 255; ++ki)
        {
            keyArray[ki] = PlainUtils.GetButtonState((ButtonState)state[(Keys)ki], (ButtonState)prestate[(Keys)ki]);
        }
    }

}


// almost exactly like XNA's GamePadState, but holds relative difference.
// a pleasantly flattened version of the GamePad multilayer structure.
public class GamePadMessage
{
    public int PacketNumber;
    public bool IsConnected;

    public ButtonRelative A;
    public ButtonRelative B;
    public ButtonRelative X;
    public ButtonRelative Y;
    public ButtonRelative ShoulderLeft;
    public ButtonRelative ShoulderRight;
    public ButtonRelative StickLeft;
    public ButtonRelative StickRight;
    public ButtonRelative Back;
    public ButtonRelative Start;
    public ButtonRelative DPadDown;
    public ButtonRelative DPadUp;
    public ButtonRelative DPadLeft;
    public ButtonRelative DPadRight;

    public Vector2 ThumbStickLeft;
    public Vector2 ThumbStickRight;
    public float TriggerLeft;
    public float TriggerRight;

    public void Update(ref GamePadState state, ref GamePadState prestate)
    {
        PacketNumber = state.PacketNumber;
        IsConnected = state.IsConnected;

        Debug.Assert((int)ButtonState.Pressed == 1); // ensure bit math still valid, in case they change it

        A = PlainUtils.GetButtonState(state.Buttons.A, prestate.Buttons.A);
        B = PlainUtils.GetButtonState(state.Buttons.B, prestate.Buttons.B);
        X = PlainUtils.GetButtonState(state.Buttons.X, prestate.Buttons.X);
        Y = PlainUtils.GetButtonState(state.Buttons.Y, prestate.Buttons.Y);
        ShoulderLeft = PlainUtils.GetButtonState(state.Buttons.LeftShoulder, prestate.Buttons.LeftShoulder);
        ShoulderRight = PlainUtils.GetButtonState(state.Buttons.RightShoulder, prestate.Buttons.RightShoulder);
        StickLeft = PlainUtils.GetButtonState(state.Buttons.LeftStick, prestate.Buttons.LeftStick);
        StickRight = PlainUtils.GetButtonState(state.Buttons.RightStick, prestate.Buttons.RightStick);
        Back = PlainUtils.GetButtonState(state.Buttons.Back, prestate.Buttons.Back);
        Start = PlainUtils.GetButtonState(state.Buttons.Start, prestate.Buttons.Start);
        DPadDown = PlainUtils.GetButtonState(state.DPad.Down, prestate.DPad.Down);
        DPadUp = PlainUtils.GetButtonState(state.DPad.Up, prestate.DPad.Up);
        DPadLeft = PlainUtils.GetButtonState(state.DPad.Left, prestate.DPad.Left);
        DPadRight = PlainUtils.GetButtonState(state.DPad.Right, prestate.DPad.Right);

        ThumbStickLeft = state.ThumbSticks.Left;
        ThumbStickRight = state.ThumbSticks.Right;
        TriggerLeft = state.Triggers.Left;
        TriggerRight = state.Triggers.Right;
    }
}

/// Commands used in a navigation message.
/// ** Any user control MUST return -1 if a command
/// is not recognized. Otherwise the containing window
/// will not attempt to interpret the command, and
/// no keyboard navigation change the focus.
public enum NavigateCommand
{
    None,

    Down,
    Up,
    Left,
    Right,

    PageDown,
    PageUp,
    PageLeft,
    PageRight,

    First,
    Last,
    Next,
    Prior,

    Enter,
    Exit,
}

// Generalization of common navigation like up/down/left/right, combining
// arrow keys and gamepad controls into single events to reduce complexity
// of controls (instead of checking multiple types of input).
public class NavigateMessage
{
    public NavigateCommand Command;
    internal float Delay;
    internal float KeyRepeats;
}

#endregion


////////////////////////////////////////////////////////////////////////////////
#region Graphics definitions

public struct WidgetGraphicsInfo
{
    public GraphicsDevice GraphicsDevice;
    public Rectangle Rectangle;
    public SpriteBatch SpriteBatch;
}

public struct TextureRectangle
{
    // this convenience exists since textures are usually packed
    // to reduce texture switching and pipeline stalls
    // (SpriteBatch performs better).
    public Texture2D texture;
    public Rectangle rectangle; // offset in texture of source image
    public Color color; // color mask for setting alpha or slight tinting

    public TextureRectangle(Texture2D newImage, Rectangle newRectangle, Color newColor)
    {
        texture = newImage;
        rectangle = newRectangle;
        color = newColor;
    }
}

#endregion


////////////////////////////////////////////////////////////////////////////////
#region Main component and core classes

public class PlainMain : Microsoft.Xna.Framework.DrawableGameComponent
{
    // the more useful relative states
    public KeyboardMessage keyboard = new KeyboardMessage();
    public MouseMessage mouse = new MouseMessage();
    public GamePadMessage gamepad = new GamePadMessage();
    public NavigateMessage navigate = new NavigateMessage();

    // the raw polled input from XNA
    KeyboardState keyboardPolled;
    MouseState mousePolled;
    GamePadState gamepadPolled;

    public UcWindow Root; // technically any type of control could be the root, but windows are most useful

    ContentManager content;
    SpriteBatch batch;

    public static SpriteFont Font; // want to avoid this too, but passing it around everywhere or caching it sucks :/
    public static Texture2D Style; // would rather avoid this, but oh well
    // http://msdn2.microsoft.com/en-us/library/bb447673.aspx


    public PlainMain(Game game)
        : base(game)
    {
        content = new ContentManager(game.Services, "content");
    }


    public override void Initialize()
    {
        Root = new UcWindow(null, UcWindow.PackerNothing);
        Root.PositionPacked = Game.Window.ClientBounds;
        Root.PositionPacked.X = 0;
        Root.PositionPacked.Y = 0;
        Root.Hints.Set(Uc.HintBits.PackWide | Uc.HintBits.PackTall | Uc.HintBits.Floating);
        base.Initialize();

        //Root.PositionQuery(Uc.PositionEnum.Packed);
        //Root.Repack();
        //root.Hints.Clear(Uc.HintBits.NeedRepack);

        // hmm, checking for IsActive the first time returns false :-/
        //if (Game.IsActive)
        Root.Hints.Set(Uc.HintBits.KeyFocused);
        Root.FocusIn();
    }


    public void Repack()
    {
        Root.PositionPacked = Root.Position = Game.Window.ClientBounds;
        Root.PositionPacked.X = 0;
        Root.PositionPacked.Y = 0;
        Root.Hints.Set(Uc.HintBits.PackWide | Uc.HintBits.PackTall | Uc.HintBits.Floating);

        Root.PositionQuery(Uc.PositionEnum.Packed);
        Root.Repack();
        Root.Hints.Clear(Uc.HintBits.RepackNeeded);
    }


    protected override void LoadGraphicsContent(bool loadAllContent)
    {
        // load textures and fonts here
        if (loadAllContent)
        {
            Font = content.Load<SpriteFont>("fonts/PlainFont");
            batch = new SpriteBatch(GraphicsDevice);
            if (Style == null) Style = content.Load<Texture2D>("textures/PlainStyleXNA");
        }
    }

    //protected virtual void OnDrawOrderChanged(object sender, EventArgs args);
    //protected virtual void OnVisibleChanged(object sender, EventArgs args);
    protected override void UnloadGraphicsContent(bool unloadAllContent)
    {
        if (unloadAllContent)
        {
            batch.Dispose();
            Style.Dispose();
        }
    }


    public override void Update(GameTime gameTime)
    {
        if (!Game.IsActive)
        {
            base.Update(gameTime);
            return;
        }

        // copy previous input
        KeyboardState keyboardPolledLast = keyboardPolled;
        MouseState mousePolledLast = mousePolled;
        GamePadState gamepadPolledLast = gamepadPolled;

        // update all input structures
        keyboardPolled = Keyboard.GetState();
        mousePolled    = Mouse.GetState();
        gamepadPolled  = GamePad.GetState(PlayerIndex.One);

        // determine differences between this frame and previous
        keyboard.Update(ref keyboardPolled, ref keyboardPolledLast);
        mouse.Update(ref mousePolled, ref mousePolledLast);
        gamepad.Update(ref gamepadPolled, ref gamepadPolledLast);

        // decompose into individual messages
        Root.MousePoll(mouse);

        Root.KeyPoll(keyboard);
        for (Keys ki = 0; ki <= (Keys)255; ++ki)
        {
            if (keyboard.IsKeyPressed(ki))
            {
                keyboard.ButtonCode = ki;
                Root.KeyPress(keyboard);
            }
            else if (keyboard.IsKeyReleased(ki))
            {
                keyboard.ButtonCode = ki;
                Root.KeyRelease(keyboard);
            }
        }

        Root.GamepadPoll(gamepad);

        // check for common keys and buttons, converting them into navigation events
        // *simplifies paying attention to multiple inputs

        if (gamepad.A == ButtonRelative.Pressed ||  keyboard.IsKeyPressed(Keys.Enter))
            CallNavigate(NavigateCommand.Enter);
        if (gamepad.B == ButtonRelative.Pressed ||  keyboard.IsKeyPressed(Keys.Escape))
            CallNavigate(NavigateCommand.Exit);

        if (keyboard.IsKeyPressed(Keys.Tab))
            if (keyboard.IsKeyDown(Keys.LeftShift) || keyboard.IsKeyDown(Keys.RightShift))
                CallNavigate(NavigateCommand.Prior);
            else
                CallNavigate(NavigateCommand.Next);

        // check directions, ensuring opposite directions
        // are mutually exclusive

        NavigateCommand hdir = NavigateCommand.None;

        if (gamepad.DPadLeft >= ButtonRelative.Down
        ||  keyboard.IsKeyDown(Keys.Left)
        ||  gamepad.ThumbStickLeft.X < -.75f
            )
            hdir = NavigateCommand.Left;

        if (gamepad.DPadRight >= ButtonRelative.Down
        ||  keyboard.IsKeyDown(Keys.Right)
        ||  gamepad.ThumbStickLeft.X > .75f
            )
            hdir = (hdir == NavigateCommand.Left) ? NavigateCommand.None : NavigateCommand.Right;

        NavigateCommand vdir = NavigateCommand.None;

        if (gamepad.DPadUp >= ButtonRelative.Down
        ||  keyboard.IsKeyDown(Keys.Up)
        ||  gamepad.ThumbStickLeft.Y > .75f
            )
            vdir = NavigateCommand.Up;

        if (gamepad.DPadDown >= ButtonRelative.Down
        ||  keyboard.IsKeyDown(Keys.Down)
        ||  gamepad.ThumbStickLeft.Y < -.75f
            )
            vdir = (vdir == NavigateCommand.Up) ? NavigateCommand.None : NavigateCommand.Down;

        // apply key repeat
        if (hdir != NavigateCommand.None || vdir != NavigateCommand.None)
        {
            if (navigate.KeyRepeats == 0 || --navigate.Delay <= 0)
            {
                // only allow one of the four directions to apply
                if (vdir != NavigateCommand.None) CallNavigate(vdir);
                else if (hdir != NavigateCommand.None) CallNavigate(hdir);
                navigate.Delay = (navigate.KeyRepeats == 0) ? 20 : 7;
                navigate.KeyRepeats++;
            }
        }
        else
        {
            navigate.KeyRepeats = 0;
        }

        // repack if dirty layout
        if (Root.Hints.IsRepackNeeded)
        {
            Root.PositionQuery(Uc.PositionEnum.Packed);
            Root.Repack();
            Root.Hints.Clear(Uc.HintBits.RepackNeeded);
        }

        base.Update(gameTime);
    }

    void CallNavigate(NavigateCommand command)
    {
        navigate.Command = command;
        Root.Navigate(navigate);
    }

    //Effect pixelShader;
    public override void Draw(GameTime gameTime)
    {   
        //if (pixelShader == null)
        //    pixelShader = content.Load<Effect>("shaders/spritebatch");

        batch.Begin(SpriteBlendMode.AlphaBlend, SpriteSortMode.Immediate, SaveStateMode.None);

        GraphicsDevice.SamplerStates[0].AddressU = TextureAddressMode.Wrap;
        GraphicsDevice.SamplerStates[0].AddressV = TextureAddressMode.Wrap;
        //batch.DrawString(Font, "Plain GUI component is being called correctly!", Vector2.Zero, Color.White);

        //PixelShader prevPixelShader = GraphicsDevice.PixelShader;
        //GraphicsDevice.PixelShader = prevPixelShader;
        //pixelShader.Begin();//SaveStateMode.SaveState);
        //pixelShader.CurrentTechnique.Passes[0].Begin();
        Root.Draw(GraphicsDevice, Root.Position, batch);

        batch.End();
        //pixelShader.CurrentTechnique.Passes[0].End();
        //pixelShader.End();

    }

}//endclass

#endregion


////////////////////////////////////////////////////////////////////////////////
#region Core user control class

public abstract class MessageTarget
{
    public virtual int HandleMessage(Message msg, object sender, object param)
    {
        return -1; // message not recognized
    }
}

/**
Summary:
    UC = user control (aka base widget from which all others derive)
*/
public class Uc : MessageTarget
{
    public Uc Parent;

    public Rectangle Position = new Rectangle(0, 0, 96, 32);

    /// Optimal position is used by the control's container
    /// for packing. The container can use it to cache the value
    /// of a QueryPosition call to avoid repetitive recursive layout.
    /// It is NOT used by the control.
    public Rectangle PositionPacked = new Rectangle(0, 0, 96, 32);

    public static readonly Rectangle PositionZero;// = new Rectangle(0,0,0,0);
    public static readonly Rectangle PositionNone = new Rectangle(int.MinValue, int.MinValue, int.MinValue, int.MinValue);
    public static readonly Rectangle PositionMaximum = new Rectangle(0, 0, int.MaxValue, int.MaxValue);

    /// used to query size
    public enum PositionEnum
    {
        Current, /// current size ?pointless
        Minimum, /// minimum allowed size (should not be smaller else content might be clipped, like button text)
        Maximum, /// maximum allowed size (should not be larger, else pointless space will show, like a single line text edit)
        Packed,  /// an optimal packed size, considering contents (Labels calc their text size, windows check all children)
                 /// note that passing this value will not change the PositionPacked field - only parents adjust that
    }

    public struct HintBits
    {
        public const uint
            Hidden = 1 << 0, /// not visible
            Disabled = 1 << 1, /// not useable
            KeyFocused = 1 << 2, /// has key focus
            MouseFocused = 1 << 3, /// has mouse focus (either mouse directly over or captured)
            NoKeyFocus = 1 << 4, /// can not receive key focus (tab will skip)
            NoMouseFocus = 1 << 5, /// can not receive mouse focus
            RepackNeeded = 1 << 6, /// needs to recalc layout because item's moved
            Floating = 1 << 7, /// indicates the control is free to move (probably has a title bar), affects tabbing

            PackFlagsMask = PackColMask | PackRowMask | PackWidth | PackHeight,
            PackColMask = 3 << 8, /// row alignment hints
              PackLeft = 0 << 8, /// hint parent to align on left side
              PackRight = 1 << 8, /// hint parent to align on right side
              PackMidCol = 2 << 8, /// center horizontally between left and right
              PackWide = 3 << 8, /// widen control as wide as possible
            PackRowMask = 3 << 10, /// row alignment hints
              PackTop = 0 << 10, /// hint parent to align on top side
              PackBottom = 1 << 10, /// hint parent to align on bottom side
              PackMidRow = 2 << 10, /// center vertically between top and bottom
              PackTall = 3 << 10, /// hint parent to heighten control as tall as possible
            PackWidth = 1 << 12, /// use given width
            PackHeight = 1 << 13, /// use given height
            PackHorizontal = 1 << 14, /// arrange horizontally (useful for scroll bar / slider direction)
            PackVertical = 1 << 15, /// arrange vertically (useful for scroll bar / slider direction)
            PackChildUniform = 1 << 16, /// arrange all children uniformly

            Collapsed = 1 << 17; /// control is collapsed or minimized

        uint bits;

        public static explicit operator uint(HintBits hints)
        {
            return hints.bits;
        }

        public void Set(uint set) {
            bits |= set;
        }
        public void Clear(uint clear) {
            bits &= ~clear;
        }
        public void Set(uint set, uint clear) {
            bits = (bits & ~clear) | set;
        }
        public static void SetParentChain(uint set, uint clear, Uc first)
        {
            Uc widget = first;
            do {
                uint newBits = (widget.Hints.bits & ~clear) | set;
                if (newBits == widget.Hints.bits) break; // stop if already set
                widget.Hints.bits = newBits;
            } while ((widget = widget.Parent) != null);
        }
        public void Toggle(uint toggle) {
            bits ^= toggle;
        }
        public bool IsSet(uint set) {
            return (bits & set) != 0;
        }
        public static void SetNeedRepack(Uc first) {
            SetParentChain(RepackNeeded, 0, first);
        }
        
        public bool IsVisible        { get { return (bits & Hidden) == 0; } }
        public bool IsHidden         { get { return (bits & Hidden) != 0; } }
        public bool IsCollapsed      { get { return (bits & Collapsed) != 0; } }
        
        public bool IsEnabled        { get { return (bits & Disabled) == 0; } }
        public bool IsDisabled       { get { return (bits & Disabled) != 0; } }
        
        public bool IsMouseFocused   { get { return (bits & MouseFocused) != 0; } }
        public bool IsKeyFocused     { get { return (bits & KeyFocused) != 0; } }
        public bool CanGetKeyFocus   { get { return (bits & (Disabled | Hidden | NoKeyFocus)) == 0; } }
        public bool CanGetMouseFocus { get { return (bits & (Disabled | Hidden | NoMouseFocus)) == 0; } }
        
        public bool IsPackLeft       { get { return (bits & PackColMask) == PackLeft; } }
        public bool IsPackRight      { get { return (bits & PackColMask) == PackRight; } }
        public bool IsPackMidCol     { get { return (bits & PackColMask) == PackMidCol; } }
        public bool IsPackWide       { get { return (bits & PackColMask) == PackWide; } }

        public bool IsPackTop        { get { return (bits & PackRowMask) == PackTop; } }
        public bool IsPackBottom     { get { return (bits & PackRowMask) == PackBottom; } }
        public bool IsPackMidRow     { get { return (bits & PackRowMask) == PackMidRow; } }
        public bool IsPackTall       { get { return (bits & PackRowMask) == PackTall; } }

        public bool IsPackWidth      { get { return (bits & PackWidth) != 0; } }
        public bool IsPackHeight     { get { return (bits & PackHeight) != 0; } }
        public bool IsFloating       { get { return (bits & Floating) != 0; } }

        public bool IsPackHorizontal { get { return (bits & PackHorizontal) != 0; } }
        public bool IsPackVertical   { get { return (bits & PackVertical) != 0; } }

        public bool IsRepackNeeded   { get { return (bits & RepackNeeded) != 0; } }
    }
    public HintBits Hints;

    public virtual string Text { get { return string.Empty; } set { } }
    public virtual float Value { get { return 0; } set { } }
    public virtual int ValueInt { get { return 0; } set { } }
    //public virtual string Label { get { return string.Empty; } set { } }


    public virtual int Predraw(GraphicsDevice gd, Rectangle rect, SpriteBatch sb) { return -1; }
    public virtual int Draw(GraphicsDevice gd, Rectangle rect, SpriteBatch sb) { return -1; }

    public virtual int Create() { return -1; }
    public virtual int Destroy() { return Parent.DeleteChild(this); }

    public virtual int FocusIn() { return -1; }
    public virtual int FocusOut() { return -1; }
    public virtual int FocusCapture(Uc widget) { return -1; }
    public virtual int Navigate(NavigateMessage ns) { return -1; }

    public virtual int KeyPoll(KeyboardMessage ks) { return -1; }
    public virtual int KeyPress(KeyboardMessage ks) { return -1; }
    public virtual int KeyRelease(KeyboardMessage ks) { return -1; }
    public virtual int MousePoll(MouseMessage ms) { return -1; }
    //public virtual int MouseMove(MouseMessage ms) { return -1; }
    //public virtual int MousePress(MouseMessage ms) { return -1; }
    //public virtual int MouseRelease(MouseMessage ms) { return -1; }
    public virtual int MouseIn(MouseMessage ms) { return -1; }
    public virtual int MouseOut(MouseMessage ms) { return -1; }
    public virtual int MouseCapture(Uc widget) { return -1; }
    public virtual int GamepadPoll(GamePadMessage gs) { return -1; }
    //public virtual int GamepadPress(GamePadStateRelative gs) { return -1; }
    //public virtual int GamepadRelease(GamePadStateRelative gs) { return -1; }

    /** 
    Summary:
        Determines additional dynamic hint information that
        can't be tested for statically from the Hints variable.
        Mainly used for windows with multiple children (like
        determining whether any subchildren can receive focus
        to know whether or not to completely skip a subgroup).
        The default implementation just returns Hints.

    Parameters:
        Uc_HintBits_ToTest:
            the bits you want to test for
            *just named that way as a mnemonic to remember the namespace
    
    Returns:
        Ignore any returned bits for which you did not pass in testHints.
    */
    public virtual HintBits HintsQuery(uint Uc_HintBits_ToTest) { return Hints; }
    
    /// Returns a rectangle for the given position information.
    /// Returns empty rectangle if the mode is unknown.
    public virtual Rectangle PositionQuery(PositionEnum mode)
    {
        switch (mode)
        {
        case PositionEnum.Packed:
            // Just return the current position
            // of the control, otherwise window packers
            // may shrink the poor control out of sight.
            // Useful for subclassed controls that have
            // not bothered to override pos query.
            //return PositionPacked;
        case PositionEnum.Current:
            return Position;
        case PositionEnum.Maximum:
            return PositionMaximum;
        case PositionEnum.Minimum:
            return PositionZero;
        default:
            return PositionNone;
        }
    }

    // Not all widgets are containers, but declare these so that
    // we don't need casting every time some code wants to append
    // a child.
    public virtual int InsertChild(Uc widget) { return -1; }
    public virtual int DeleteChild(Uc widget) { return -1; }

    public virtual int Reposition(Rectangle rect) {
        if (rect.X != int.MinValue) Position.X = rect.X;
        if (rect.Y != int.MinValue) Position.Y = rect.Y;
        if (rect.Width != int.MinValue) Position.Width = rect.Width;
        if (rect.Height != int.MinValue) Position.Height = rect.Height;
        HintBits.SetNeedRepack(this);
        return 0; 
    }
    public virtual int Reposition(Rectangle rect, uint bits)
    {
        Debug.Assert((bits & ~Uc.HintBits.PackFlagsMask) == 0);
        Hints.Set(bits, HintBits.PackFlagsMask);
        return Reposition(rect);
    }
    public virtual int Repack()
    {
        Position = PositionPacked;
        //Flags.Clear(HintBits.NeedRepack); (let parent do this)
        return 0;
    }


    public delegate void ActionDelegateInt(Uc uc, int value);
    public delegate void ActionDelegateFloat(Uc uc, float value);

    protected static void ActionCallbackIntDummy(Uc uc, int value) {}
    protected static void ActionCallbackFloatDummy(Uc uc, float value) { }

    public static Uc DummySingleton = new Uc(); // dummy control owner, to avoid (if != null) tests everywhere

    protected Uc() { }


    // translate message into function call
    // This is rarely needed, especially if only basic methods are called or
    // the caller knows exactly what type the object is; but it can be
    // convenient when it does not know and wants to try a message anyway.
    public override int HandleMessage(Message msg, object sender, object param)
    {
        switch (msg) {
        case Message.Draw:
            {
                WidgetGraphicsInfo wgi = (WidgetGraphicsInfo)param;
                //WidgetGraphicsInfo test = stackalloc WidgetGraphicsInfo[1];

                return Draw(wgi.GraphicsDevice, wgi.Rectangle, wgi.SpriteBatch);
            }
        case Message.Predraw:
            {
                WidgetGraphicsInfo wgi = (WidgetGraphicsInfo)param;
                return Predraw(wgi.GraphicsDevice, wgi.Rectangle, wgi.SpriteBatch);
            }
        case Message.FocusIn:
            return FocusIn();
        case Message.FocusOut:
            return FocusOut();
        case Message.FocusCapture:
            return FocusCapture((Uc)param);
        case Message.GamepadPoll:
            return GamepadPoll((GamePadMessage)param);
        //case Message.GamepadPress:
        //    return GamepadPress((GamePadStateRelative)param);
        //case Message.GamepadRelease:
        //    return GamepadRelease((GamePadStateRelative)param);
        case Message.Navigate:
            return Navigate((NavigateMessage)param);
        case Message.KeyPoll:
            return KeyPoll((KeyboardMessage)param);
        case Message.KeyPress:
            return KeyPress((KeyboardMessage)param);
        case Message.KeyRelease:
            return KeyRelease((KeyboardMessage)param);
        case Message.MousePoll:
            return MousePoll((MouseMessage)param);
        //case Message.MouseMove:
        //    return MouseMove((MouseMessage)param);
        //case Message.MousePress:
        //    return MousePress((MouseMessage)param);
        //case Message.MouseRelease:
        //    return MouseRelease((MouseMessage)param);
        case Message.MouseIn:
            return MouseIn((MouseMessage)param);
        case Message.MouseOut:
            return MouseOut((MouseMessage)param);
        case Message.MouseCapture:
            return MouseCapture((Uc)param);
        default:
            return -1;
        }
    }
}


#endregion


////////////////////////////////////////////////////////////////////////////////
#region Useful miscellaneous functions

public static class PlainUtils
{
    public static ButtonRelative GetButtonState(ButtonState state, ButtonState prestate)
    {
        return (ButtonRelative)((uint)state << 1) | (ButtonRelative)(state ^ prestate);
    }

    /// Parses number from string - needed because Int.TryParse ignores
    /// my style specification, chokes when encountering a decimal
    /// (who cares, ignore the decimal!), and does not even exist
    /// on the .NET compact framework for Xbox.
    /// So, since this functionality does not belong in the
    /// individual controls, here it is...
    public static int ParseNumberInt(string text)
    {
        int value = 0;
        bool signed = false;
        int i = 0;

        // find first number, skipping any letters are whitespace
        for (; i < text.Length; ++i)
        {
            char c = text[i];
            if (c >= '0' || c <= '9' || c == '-') break;
        }
        // parse numbers
        for (; i < text.Length; ++i)
        {
            char c = text[i];
            if (c >= '0' || c <= '9')
                value = value * 10 + c - '0';
            else if (c == '\'' || c == '_')
            // Do nothing and ignore thousands separators.
            // Note that apostrophes or underscores are used
            // as thousands separators - NEVER commas, which
            // are used as list separators. The underscore
            // is borrowed from D, while the apostrophe is
            // borrowed from the intelligent Swiss (too bad
            // they also use commas as radix separators, making
            // it impossible to know whether array={23,45}
            // means 23 and 45 or 23.45).
            { }
            else if (c == '-')
                signed = true;
            else
                break;
        }

        return (signed) ? -value : value;
    }

    public static float ParseNumber(string text)
    {
        float integer = 0;
        float numerator = 0;
        float exponent = 0;
        float denominator = 1;
        bool signed = false;
        int i = 0;

        // find first number, skipping any letters are whitespace
        for (; i < text.Length; ++i)
        {
            char c = text[i];
            if (c >= '0' || c <= '9' || c == '-') break;
        }

        int part = 0;
        // parse numbers
        for (; i < text.Length; ++i)
        {
            char c = text[i];
            if (c >= '0' || c <= '9')
            {
                c -= '0';
                switch (part)
                {
                case 0:
                    integer = integer * 10 + c;
                    break;
                case 1:
                    numerator = numerator * 10 + c;
                    denominator *= 10;
                    break;
                case 2:
                    exponent = exponent * 10 + c;
                    break;
                }
            }
            else if (c == '\'' || c == '_')
            // Do nothing and ignore thousands separators.
            // Note that apostrophes or underscores are used
            // as thousands separators - NEVER commas, which
            // are used as list separators. The underscore
            // is borrowed from D, while the apostrophe is
            // borrowed from the intelligent Swiss (too bad
            // they also use commas as radix separators, making
            // it impossible to know whether array={23,45}
            // means 23 and 45 or 23.45).
            { }
            else if (c == '.')
                // so it's not internationally compatible,
                // but it satisfies the huge target
                // demographics of China, India, Japan, US
                part = 1;
            else if (c == 'e')
                part = 2;
            else if (c == '-')
                signed = true;
            else
                break;
        }

        float value = (integer + numerator / denominator) * (float)Math.Pow(10, exponent);
        return (signed) ? -value : value;
    }
}
#endregion


}//endnamespace




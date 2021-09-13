//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface definitions.
//
//----------------------------------------------------------------------------
#pragma once


struct KeyboardMessage
{
    enum Message
    {
        MessageEnter,
        MessageExit,
        MessagePress,
        MessageRelease,
        MessageCharacter,
    };
    Message message;
    UINT32 button;      // key last pressed or released
    UINT32 character;   // Unicode character
    UINT32 repeatCount; // number of presses
};


struct MouseMessage
{
    enum Message
    {
        MessageEnter,
        MessageExit,
        MessagePress,
        MessageRelease,
        MessageMove,
        MessageScroll
    };
    enum Button
    {
        ButtonNone,
        ButtonLeft,
        ButtonRight,
        ButtonMiddle,
        ButtonX,
    };
    Message message;
    Button button; // button last pressed or released - applicable within a button press/release message
    float x, y; // position in child
    float xDif, yDif; // relative difference since last time for mouse move or wheel scroll
    UINT32 repeatCount; // number of presses (single click, double, triple..)
};


// Generalization of common navigation like up/down/left/right, combining
// arrow keys and into single events to reduce complexity of control logic.
struct NavigateMessage
{
    enum Message
    {
        MessageNone,

        MessageDown,
        MessageUp,
        MessageLeft,
        MessageRight,

        MessagePageDown,
        MessagePageUp,
        MessagePageLeft,
        MessagePageRight,

        MessageFirst,
        MessageLast,
        MessageNext,
        MessagePrior,

        MessageEnter,
        MessageExit, // cancel/quit
    };

    Message message;
    UINT32 repeatCount;
};


// Many controls generate events, which are then sent on to their targets.
// The owners could be the control's container (like Win32) but more
// often, it will be a callback in the main app, or even linked directly
// to another control, to bypass the main app middleman glue. The only
// requirement is that the owner should always exist so long as the
// generating control does - hence the requirement to inherit from
// RefCountBase (UI controls already do).
//
template<typename Callback, typename T = RefCountBase>
struct UiDelegate
{
    RefCountPtr<T> target;
    Callback* callback;

    inline UiDelegate() throw()
    :   target(NULL),
        callback(NULL)
    { }

    inline UiDelegate(RefCountBase* newTarget, Callback* newCallback)
    :   target(newTarget),
        callback(newCallback)
    { }

    inline void Set(RefCountBase* newTarget, Callback* newCallback)
    {
        target.Set(newTarget);
        callback = newCallback;
    }

    inline void Clear()
    {
        target.Clear();
        callback = NULL;
    }

    inline bool IsSet() throw()
    {
        return callback != NULL;
    }

    bool Get(__deref_opt_out RefCountBase** currentTarget, __deref_opt_out Callback** currentCallback)
    {
        // If both are null, this essentially returns whether or not any is set.
        if (currentTarget != NULL)
            *currentTarget = target;

        if (currentCallback != NULL)
            *currentCallback = callback;

        return IsSet();
    }
};

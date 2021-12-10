; GUI definitions, structures, macros
; Messages, Common flags, GuiObj structure, WindowObj, ButtonObj...
; Required by guicode.asm and guiobjs.asm
;
; NOTE that many of the options/variables/flags defined for items have not
; been fully implemented in the code. Dreams are much easier than reality.
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

%define GuiDefsInc

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Message types
Msg:

; Messages:
;   Unlike Windows, which has thousands of messages, this simple GUI wouldn't
;   ever exceed 256. MS Windows has a message for every miscellanous thing,
;   while my GUI only has messages for things that really matter. So AL was
;   chosen as the message holder, leaving the remaining upper bits for
;   optional flags.

; Common messages vs Specific messages:
;   After much pondering, I finally decided to make common GUI messages start
;   from 0 upward and specific messages unique to a certain item start at -1
;   downward. Two other ideas included: making common messages 0-127 and
;   specific messages 128-255, or making specific messages a subset of common
;   messages with the specific message in AH. By making messages extend
;   either direction from zero, it simplifies message branching by not
;   needing to test the upper bit (128) and subtract 128, or two comparisons
;   (AL then AH), or even two jump tables. Instead (after byte sign extension)
;   there is one jump table and no extra comparisons (other than the range
;   checking which would have to be done in any case).

; Message order:
;   Messages are somewhat grouped by category, but are also arranged so that
;   that the most commonly used ones (specifically owner messages) are put
;   at either end of the range (close to 0 or close to 255), making the jump
;   tables smaller.

;컴컴컴컴컴컴컴컴컴컴 FUNDAMENTAL
.Created        equ 0           ;item was created and should initialize itself
.Destroyed      equ 1           ;release resources used by item
.Redraw         equ 2           ;informs item it should redraw itself now
.FlagsChanged   equ 3           ;flags have been changed
.MovedSized     equ 4           ;item was moved or resized
.Time           equ 5           ;item time is now or past due
.Focus          equ 6           ;item focus gained/lost, either Tab key or mouse activation
.Help           equ 7           ;request help from item

;컴컴컴컴컴컴컴컴컴컴 INPUT
.KeyPress       equ 8           ;key press
.KeyRelease     equ 9           ;key release
.KeyChar        equ 10          ;character
.KeyIn          equ 11          ;key focus in, usually from being tabbed to
.KeyOut         equ 12          ;key focus out, usually from being tabbed from
.MousePrsRls    equ 13          ;button press or release
.MouseMove      equ 14          ;simple move over item, no button change
.MouseIn        equ 15          ;mouse focus in, entered item's boundary
.MouseOut       equ 16          ;mouse focus out, exited item's boundary

;컴컴컴컴컴컴컴컴컴컴 CONTAINER RELATED
.Create         equ 17          ;sent to a container to create an item or main layer to create container window
.Destroy        equ 18          ;same as above but to destroy a container/item
.RedrawItem     equ 19          ;item within window needs redrawing, sent from item to container
.SetFlags       equ 20          ;request flags be changed properly by container
.MoveSize       equ 21          ;request resizing/repositioning of object

.SetItemFocus   equ 22          ;set item or group that appears active
.SetKeyFocus    equ 23          ;set which item has key focus
.SetMouseFocus  equ 24          ;set which item receives mouse focus, usually for an item to temporarily grab all mouse input for itself
.SetLayer       equ 25          ;request item's zlayer order be changed

.GetItemFocus   equ 26          ;get item or group that appears active
.GetKeyFocus    equ 27          ;get which item has key focus
.GetMouseFocus  equ 28          ;get which item receives mouse focus, usually for an item to temporarily grab all mouse input for itself
.GetLayer       equ 29          ;get item's zlayer order

.Ignore         equ 127

; Other messages to be added:
;
; Get item's effective flags, considering all container's flags
;   To get an item's effective flags, all of its container's flags are
;   combined with it. For example, if an item can receive key focus, but
;   its container can not, then that item's effective state is no key focus.
;   Similarly with visibility, if an item is visible, but its container is
;   not, truly neither is the item.
; Get item at row/column coordinate
;   This could used for getting help on an item. If you click on the
;   question mark on a title bar, and then move the cursor over an item,
;   the code would need to know which item is the cursor rests over. This
;   message could be sent directly to a window or from the top level with
;   a specified depth. It is very similar to SendMouseMsg.

;컴컴컴컴컴컴컴컴컴컴
; Key Focus:
;   Only one item have key focus at any given time in a container. Whether
;   or not the container itself currently has focus, there is always one item
;   that has active key focus item (unless the container has no items in it).
;   Individual items can be grouped, allowing each group to have its own
;   default item. Although only one item can actually be the active item and
;   receive key input, several items can be informed of focus changes and
;   even make themselves falsely appear active (as if they all simultaneously
;   had focus) when certain item flags are set.
;
; Common usage:
;   The next/previous item within a group
;   The next/previous group
;   A specific item/specific group
;   Changing the default item of a specific group
;
; Focus setting behaviour:
;   Focus be set to either a single item or whole group, relatively or
;   absolutely. Absolute setting can activate a specific item, or the group
;   that item is in. Relative setting seeks either forward or backward
;   relative the active item or to some other specified item. If the focus
;   change fails at some point, the routine will still continue and perform
;   other operations requested. For example, if both the item and group flags
;   were given but the specified item could not be set, it would still try to
;   set the group. If the container flag was given but any focus change
;   within the container failed, it would still active the container.
;
; Container/group/item flags:
;   These three flags combined in different ways tell the same function call
;   to perform focus changes in a variety of ways. When the item flags is
;   given, the active item of a specific group is set (the active group
;   remains unchanged). When the group flags is given, the active group is
;   changed (the active item of that group becomes the active item of the
;   container). To set an item both the active item of a group and the active
;   group, combine both flags. With the container flag set, the container is
;   activated.
;
; Splitting key input:
;   Since key focus can truly only belong to one item at a time, to split key
;   input between separate but closely paired items (like a list and text
;   prompt), an invisible item can be used to interpret keystrokes and then
;   pass them onto the correct item according the key pressed. For example, a
;   text prompt and list might be paired, so that all alphanumeric characters
;   are sent to the text prompt but up/down arrow keys are sent to the list.
;   The invisible item would truly be what had focus, but it would do nothing
;   more than receive the input and chain it.
;
;   The list and prompt would look though as if they had focus because they
;   are part of the same group and would have their item focus flags on.
;   Using a separate "invisible" item to do this might seem rather clumsy
;   and wasteful, but it's really more elegant than putting the equivalent
;   code in the owner for the container, and no slower because of the minimal
;   processing it does.
;

; These flags are used by: Focus, SetItemFocus, GetItemFocus
FocusMsgFlags:
.SetItem        equ 256         ;activate item in group (does not alone activate group) otherwise the existing active item of the group is used
.SetGroup       equ 512         ;activate group in window (does not alone activate container)
.GetItem        equ .SetItem    ;alias, get active item of group
.GetGroup       equ .SetGroup   ;alias, get active group of container
.SetContainer   equ 1024        ;activates item's container (chaining up), or means a new container activated and item's container either lost or gained focus
.Relative       equ 2048        ;relative to current item, will wrap / else absolute item index given
.Specified      equ 4096        ;relative seek start from item specified, otherwise from current item
.Reverse        equ 8192        ;seek previous item, otherwise relative seeks procede forward
.Recurse        equ 32768       ;recurse to get contained item in lower levels
.Silent         equ 65536       ;steals focus without sending any messages to previous item, all flags also remain the same so other items still appear active
.NoWrap         equ 131072      ;relative should not wrap (if there are no more items, the call will fail)
.ByMouse        equ 262144      ;focus was set because mouse was moved over item
.Repeat         equ 33554432    ;repeated keypress (key held down)

; These flags are used by: KeyPress,KeyRelease,KeyChar,KetIn,KeyOut,SetKeyFocus
KeyMsgFlags:
.SetItem        equ 256
.SetContainer   equ 1024        ;grab key focus all the way up to the top level
.Recurse        equ 32768       ;recurse to get contained item in lower levels
.Silent         equ 65536       ;steals focus without sending any messages to previous item
.WindowInOut    equ 131072      ;entered/exited main window (MS Window's compile)
.ByMouse        equ 262144      ;focus was set because mouse was moved over item
.Repeat         equ 33554432    ;repeated keypress (key held down)

; These flags are used by: MousePrsRls,MouseMove,MouseIn,MouseOut,SetMouseFocus
MouseMsgFlags:
.SetItem        equ 256         ;gained focus
.SetContainer   equ 1024        ;grab mouse focus all the way up to the top level
.VerticalPush   equ 2048        ;mouse cursor pushed beyond top/bottom boundary
.HorizontalPush equ 4096        ;beyond left/right boundary
.Reset          equ 8192        ;resets mouse boundaries to container maximum
.Recurse        equ 32768       ;recurse to get contained item in lower levels
.Silent         equ 65536       ;steals focus without sending any messages to previous item, all flags also remain the same so other items still appear active
.MouseMoved     equ 131072      ;mouse was moved
.WindowInOut    equ 262144      ;entered/exited main window (MS Window's compile)
.Specified      equ 524288      ;get item at position

LayerMsgFlags:
.SetItem        equ 256         ;set item's layer order
.SetContainer   equ 1024        ;bring container to back or front also
.Specified      equ 4096        ;item gave another to be relative to
.Reverse        equ 8192        ;sets item to back rather than front

MoveSizeFlags:
.SizedHeight    equ 256         ;item sized, height was changed
.SizedWidth     equ 512
.MovedRow       equ 1024        ;item moved, top row was changed
.MovedCol       equ 2048
.MovedLayer     equ 4096
.Invisible      equ 8192        ;does not redraw anything
.Silent         equ 65536       ;sends no messages to item

;컴컴컴컴컴컴컴컴컴컴
TextPromptMsg:
.Change         equ 255         ;text was modified (typed character/bkspc/del)
.Select         equ 254         ;caret was moved (left/right/home/end/mouse click)
.Scroll         equ 253         ;text was scrolled
.ReallocString  equ 252         ;request string reallocation, when the number of characters typed exceeds the maximum size

;컴컴컴컴컴컴컴컴컴컴
PushButtonMsg:
.Change         equ 255         ;button pressed/released/toggled

;컴컴컴컴컴컴컴컴컴컴
AtrListMsg:
.Change         equ 255         ;one of the attribute values was changed by user
.Activate       equ 254         ;attribute was left clicked or Enter was pressed
.AltActivate    equ 253         ;right click or Space was pressed
.GetValue       equ 252         ;needs name/value strings from owner (return esi=string ptr, ecx=length, ecx=-1 if ASCIIZ)
.Select         equ 251         ;different attribute was selected
.Scroll         equ 250         ;list was scrolled

;컴컴컴컴컴컴컴컴컴컴
ScrollHandleMsg:
.Change         equ 255         ;value was changed
.Release        equ .Change     ;mouse was released
.Scroll         equ 254         ;handle scrolled
.Grab           equ 253         ;mouse button is pressed down

;컴컴컴컴컴컴컴컴컴컴
TabStripMsg:
.Activate       equ 255         ;attribute was left clicked
.Select         equ 254         ;different tab was selected
.Hover          equ 253         ;tab was hovered over

;컴컴컴컴컴컴컴컴컴컴
MenuMsg:
.Activate       equ 255         ;menu choice was chosen
.Select         equ 254         ;different choice was selected
; the messages below here are only for communication between menu objects,
; not passed to the owner.
.Cancel         equ 253
.Rechain        equ 252         ;significant attribute change in submenu
.Change         equ 251         ;name change or minor attribute changed
.Open           equ 250         ;a submenu was opened, menu (if owner) should select newly opened branch
.Close          equ 249         ;a submenu was closed, menu should ensure that key focus is still valid
.MouseIn        equ 248         ;mouse was moved in to menu
.MouseOut       equ 247         ;mouse was moved out from menu
.Destroy        equ 246
.MouseDestroy   equ 256         ;mouse moved out of menu
.KeyDestroy     equ 512         ;escape key pressed
.ChoiceDestroy  equ 1024        ;choice was activated
.OwnerDestroy   equ 2048        ;another item owned the menu
;there is no hover message because moving the cursor over a choice
;immediately selects it


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Object data structures
;컴컴컴컴컴컴컴컴컴컴

;컴컴컴컴컴컴컴컴컴컴
GuiObj:
.Pos            equ -28 ;(4)    dword for top row and left column
.Top            equ -28 ;2      offset of object within parent window,
.Left           equ -26 ;2      not the screen offset (in pixels)
.Size           equ -24 ;(4)    dword for height and width
.Height         equ -24 ;2      size in pixels (not stupid twips)
.Width          equ -22 ;2
.Idx            equ -20 ;2      index of object in parent window list
.ExtraIdx       equ -18 ;2      don't know yet, maybe a help context id or id for group items
.Flags          equ -16 ;4      flags to determine object behaviour (invisible, disabled, gets focus, mouse responsive, needs redrawing)
 .Null          equ 1           ;item does not exist, should never be sent messages (this flag is used to delete an item in a container without shifting all the others down one)
 .Hidden        equ 2           ;does not receive draw messages because it has no visible form or is currently invisible. Hidden items are not also disabled, and can still receive any mouse or key input sent their way. This allows an item to stay invisible but appear upon mouse over.
 .MouseFocus    equ 4           ;cursor is currently over item or item has grabbed mouse focus
 .MouseFocusB   equ 2           ;bit
 .NoMouseFocus  equ 8           ;does not receive mouse input (like a static picture or label)
 .KeyFocus      equ 16          ;item has key focus. Note this is only set if the item currently has key focus AND its container has key focus. It is also possible to have this flag set without being active (like a temporary popup menu or tooltip)
 .KeyFocusB     equ 4           ;bit
 .NoKeyFocus    equ 32          ;does not receive keyboard input (like a title bar or label)
 .AllFocus      equ 64          ;items receive all focus messages, not just significant ones, like being the active item and losing focus or vice versa. other high level focus changes, like container or group are by default not made aware to the item.
 .GroupStart    equ 128         ;starts a new tab group, stopping focus advancement on either this item or active group item
 .ItemFocus     equ 256         ;item is currently active in the group (0=item focus, 1=no item focus), regardless of whether that group is active
 %if FocusMsgFlags.SetItem != .ItemFocus
  %error "ItemFocusFlags and GuiObj flags must match!"
 %endif
 %if KeyMsgFlags.SetItem != .ItemFocus
  %error "KeyFocusFlags and GuiObj flags must match!"
 %endif
 .GroupFocus    equ 512         ;item is in active group (0=group focus, 1=no group focus), regardless of whether the container is active
 .ContainerFocus equ 1024       ;item's container is active
 .NotFullFocus  equ .ItemFocus|.GroupFocus|.ContainerFocus  ;if any bit is set, item does not have full focus (note: since zero is easier to test for than all ones, the flags are reversed, so all three flags zero means full focus)
 .NoItemFocus   equ 2048        ;the item is skipped when looking for the next item to receive focus (when pressing tab). Note an item CAN still receive item focus if explicitly set.
 .RedrawBg      equ 16384       ;indicates to container an item's background needs redrawing; indicates to item that its background has been redrawn and that it must now completely redraw itself
 .RedrawPartial equ 32768       ;item needs to redraw part of itself, not neccessarily all of it
 .RedrawSpecial equ 65536       ;item specific flag (different meaning to each item)
 .RedrawForced  equ 131072      ;tells item it some other item redrew itself, forcing this one to also be redrawn
 .Redraw        equ .RedrawPartial|.RedrawBg|.RedrawSpecial|.RedrawForced ;either part or all of the item needs redrawing
 .RedrawHandled equ 262144      ;tells container this item handles setting the redrawn update area, usually because it is a window that contains subitems, otherwise the container does it for the item
 .RedrawComplex equ 524288      ;more complex zlayered redrawing, since items may be overlapped (painter's algorithm)
 .FixedLayer    equ 1048576     ;drawing layer should never change, used by backgrounds or foreground status windows
 .FixedPosition equ 2097152     ;position should never change, used by fixed items like nonmoveable windows
 .Disabled      equ 4194304     ;item can not receive either mouse or keyboard input. Unlike NoKeyFocus and NoMouseFocus which are fairly permanent attributes, Disabled may change often depending on program circumstancs.
 .FewOwnerMsgs  equ 1073741824  ;tells item to only send important messages (like a menu choice being chosen, not simply selected; or a tab being clicked, not simply hovered)
.Container      equ -12 ;4      ptr to containing window's data structure
.Owner          equ -8  ;4      item or indirect callback to owner, notified of significant changes in data (technically, since only the item ever uses this variable, any 4 byte info can be stored here)
.Misc           equ -8
.Code           equ -4  ;4      item message handler (or intercepting code)
.SizeOf         equ 28
;.SizeShl        equ 5

.DefFlags    equ .RedrawBg|.ItemFocus|.GroupFocus|.ContainerFocus

; An item need not have this entire structure if certain properties are
; unused (although it hurts only a few bytes to have them). For example, an
; item that has neither position nor size can leave them out. The container
; will not use them if the Hidden flag is set. If an item is part of a really
; simple container (no zlayering or key focus), it doesn't need an index
; value. The other values should always be included, and the code address is
; absolutely essential.
;
; Focus Clarification:
;   Active focus is not synonymous with key or mouse focus. Each is
;   independant from the other, although one frequently causes another. For
;   example, mouse focus (moving the mouse over the item) may cause it to
;   grab item focus, which it follows by taking key focus.
;
;   Some items can not receive key input, but should still be alerted to focus
;   changes (like a title bar). So AllFocus is set for such an item. Focus
;   messages do not necessarily indicate that key input will be sent to
;   the item, but rather its container or one of the items in its group has
;   received focus. Only if all three flags are set off (reversed for simpler
;   testing) can the item assume that it is active.

;컴컴컴컴컴컴컴컴컴컴
OwnerCallbackObj:
.Code           equ -4  ;4      program code address

; Originally owners of GUI items were direct code addresses. While effective,
; this made it near impossible to make the owner of one item another item,
; (like a list owning its vertical scroll handle) because the data structure
; of the list was not passed in the message.
;
; With merely a single pointer to owner code, this seemingly pointless, tiny
; structure was created to allow an item's owner to be either program code
; or another item. It is basically a GUI object without the object, only the
; code address (both are at offset -4).

;컴컴컴컴컴컴컴컴컴컴
struc TimerObj
.Order:         resb 1          ;index to next item
.CurOrder:      resb 1          ;current item index (temporary variable)
.Idx:           resb 1          ;index of this item
.Flags:         resb 1          ;really just for alignment
.Owner:         resd 1          ;item or indirect callback to owner
.Time:          resd 1          ;time of next call
.Interval:      resd 1          ;milliseconds between calls
.SizeShl        equ 4
endstruc

; All active timers will be checked each time through the GUI loop. They can
; either be called every time through the GUI loop or timed to a regular
; interval. On all but very slow computers, the entire loop will be completed
; faster than the frame rate, so untimed items (zero interval) may be called
; several times between frames.
;
; A timed item could be an animation, or a scroll handle scrolling because
; of clicking on either side of it. An untimed item could loading a large
; file. You would want to allow the user abort the lengthy process.
;
; Items can create timers, destroy timers, and change the order relative to
; other items. These actions can even be done from within a timer call, but
; the change may not take effect until the next loop. Items are allowed to
; access their timer structure directly, to set their own interval and time
; of next call, but should never touch flags or order directly.

%ifdef UseWindowCode
;컴컴컴컴컴컴컴컴컴컴
struc WindowObj
.TotalItems:    resw 1
.MaxItems:      resw 1          ;maximum items that may be created
.FocusItem:     resd 1          ;ptr to item which currently has focus
.KeyItem:       resd 1          ;ptr to item which currently has key input
.MouseItem:     resd 1          ;ptr to item which mouse cursor was last over
.MouseTopLeft:                  ;top/left
.MouseTop:      resw 1          ;top pixel row of active mouse item's boundary area
.MouseLeft:     resw 1          ;left column of active mouse item's boundary
.MouseBtmRight:                 ;bottom/right
.MouseBtm:      resw 1          ;...
.MouseRight:    resw 1          ;...
.RedrawBounds:                  ;all four redraw boundaries
.RedrawTopLeft:                 ;top/left redraw boundaries
.RedrawTop:     resw 1          ;top pixel row of area to redraw
.RedrawLeft:    resw 1          ;...
.RedrawBtmRight:                ;bottom/right redraw boundaries
.RedrawBtm:     resw 1          ;...
.RedrawRight:   resw 1          ;...
.Background:    resd 1          ;background color, ptr to bitmap, ptr to tile... (note the window itself does NOT use these)
.Flags:         resd 1          ;determines window's options
 .BgExists      equ 7           ;draw background, otherwise transparent
 .BgIsBorder    equ 1           ;typical gray bg with raised border (only supported for now)
 .BgIsColor     equ 2           ;solid color
 .BgIsPic       equ 4           ;picture
 .KeyRecurse    equ 8           ;flags key focus is currently being set (to prevent recursion from messing with a previous call)
;컴컴컴컴
.Items:                         ;all the objects in a window (8*x)
.ItemsPtr:      resd 1          ;ptr to item data
.ItemsLayer:    resw 1          ;mouse layer, index points to another item in the window list
.ItemsKeyIdx:   resw 1          ;key order, index points to another item in the window list
.Items_size     equ 8

.DefFlags    equ GuiObj.DefFlags|GuiObj.RedrawHandled|GuiObj.GroupStart
endstruc

struc WindowObjItems
.Ptr:           resd 1          ;ptr to item data
.Layer:         resw 1          ;mouse layer, index points to another item in the window list
.KeyIdx:        resw 1          ;key order, index points to another item in the window list
.SizeOf:                        ;size of each entry in container list
endstruc

%endif

%ifdef UseFrameCode
;컴컴컴컴컴컴컴컴컴컴
%ifndef UseWindowCode
%error "UseWindowCode must be defined to use frames"
%endif
FrameObj.DefFlags equ GuiObj.DefFlags|GuiObj.RedrawHandled|GuiObj.GroupStart|GuiObj.FixedLayer|GuiObj.FixedPosition

%endif

%ifdef UseWindowBgCode
;컴컴컴컴컴컴컴컴컴컴
WindowBgObj.DefFlags  equ GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.FixedLayer|GuiObj.FixedPosition
;(no further variables because it uses those of the container, thus a
; WindowBg item should only be contained within a true Window)
%endif

%ifdef UseMainBgCode
;컴컴컴컴컴컴컴컴컴컴
MainBgObj.DefFlags  equ GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.FixedLayer|GuiObj.FixedPosition|GuiObj.AllFocus
%endif

%ifdef UseTitleBarCode
;컴컴컴컴컴컴컴컴컴컴
struc TitleBarObj
.TextPtr        resd 1          ;string is not null terminated
.TextLen        resd 1          ;number of characters in title text
.Flags          resb 1
.CloseButton    equ 1           ;"X"  has close button
.HelpButton     equ 2           ;"?"  has help button in upper right corner
.MaxButton      equ 4           ;"<<" has maximize button
.MinButton      equ 8           ;">>" has minimize button
.GroupIndicate  equ 128         ;changes active indication for group level

.DefFlags    equ (GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.AllFocus)^GuiObj.ItemFocus
endstruc
%endif

%ifdef UseTextPromptCode
;컴컴컴컴컴컴컴컴컴컴
struc TextPromptObj
.TextPtr:       resd 1          ;string is not null terminated
.TextLen:       resd 1          ;number of characters in text
.MaxLen:        resd 1          ;maximum number of characters allowed.
.CaretChar:     resd 1          ;character position of caret
.CaretRow:      resw 1          ;(unused for now)
.CaretCol:      resw 1
.SelectChar:    resd 1          ;character position of selection start
.SelectRow:     resw 1          ;(unused for now)
.SelectCol:     resw 1
.ScrollChar:    resd 1          ;character position of scroll start
.ScrollYX:                      ;pixel position of text offset
.ScrollY:       resw 1          ;base top pixel row
.ScrollX:       resw 1          ;base pixel of text prompt's left column
.Flags:         resd 1
 .AlignLeft     equ 0           ;characters start from the left column
 .AlignRight    equ 1           ;characters align to right column
 .AlignCenter   equ 2           ;length of string is centered
 .AlignMask     equ 3
 .BlockLeft     equ 0           ;keep characters on left side visible
 .BlockRight    equ 4           ;keep characters on right side visible
 .BlockCenter   equ 8           ;do not allow text to extend either direction off the screen, wrap both sides
 .BlockMask     equ 12
 .Locked        equ 16          ;text can't be edited
 .Invalid       equ 32          ;text should should be specially highlighted for error (maybe all red)

.DefFlags    equ GuiObj.DefFlags
endstruc

; -the invalid flag can be used to show an entered is not legal. this would
;  mainly be used for numeric values that were out of range.
; -generates messages when the text is changed and when the caret moves.
%endif

%ifdef UseListCode
;컴컴컴컴컴컴컴컴컴컴
struc ListObj
.Function:      resd 1
.Rows:          resw 1          ;number of choices
.Columns:       resw 1
.SelectRowCol:                  ;current row/col position in list
.SelectRow:     resw 1
.SelectCol:     resw 1
.ScrollTop:     resw 1          ;base row of list's top
.TotalWidth:    resw 1          ;sum of all column widths
.ScrollYX:                      ;base row/col pixel offset of list's top/left
.ScrollY:       resw 1
.ScrollX:       resw 1
;컴컴컴컴
.ColItems:                      ;column information
.Flags:         resd 1          ;flags about a column
 .AlignLeft     equ 0           ;characters start from the left column
 .AlignRight    equ 1           ;characters align to right column
 .AlignCenter   equ 2           ;length of string is centered
 .AlignMask     equ 3
 .BlockLeft     equ 0           ;keep characters on left side visible
 .BlockRight    equ 4           ;keep characters on right side visible
 .BlockCenter   equ 8
 .BlockMask     equ 12
 .IsPicture     equ 16          ;function returns ptr to picture instead of text
 .MergedColumns equ 32          ;all columns are merged into single row
 .UniqueColumns equ 64          ;each column can have its own unique attributes
.Order:         resw 1          ;index to column (columns can be shifted around)
.Width:         resw 1          ;width of a single column
.Id:            resw 1          ;unique to column even if columns have been moved

.DefFlags    equ GuiObj.DefFlags
endstruc

; -a text function is given a row and column id (which must be valid) and
; returns a ptr to that cell's [character string and its length] or picture.
; -generates messages when the choice is changed and when the list is scrolled.
; -column widths are only included and used if there are at least two columns.
%endif

;컴컴컴컴컴컴컴컴컴컴
;FileListObj:
;
; -exactly the same as a normal TextList except that the source function is
;  fixed, the columns are always one, and the list items are displayed
;  differently. Files are shown normally, but folders are shown with
;  parenthesis around them. The file/folder is stored in the first byte
;  before the filename.

%ifdef UseScrollHandleCode
;컴컴컴컴컴컴컴컴컴컴
struc ScrollHandleObj
.Range:         resd 1          ;maximum value, total range of values
.Value:         resd 1          ;current value
.Base:          resd 1          ;base value to add to value (in case range does not start at 0)
.SmallStep:     resd 1          ;how much to scroll when left-clicking (row)
.LargeStep:     resd 1          ;how much to scroll when right-clicking (page)
.ScrollSpeed:   resd 1          ;scroll delay in milliseconds

;.DefFlags    equ GuiObj.DefFlags|GuiObj.NoKeyFocus
.DefFlags    equ (GuiObj.DefFlags|GuiObj.NoKeyFocus)^GuiObj.ItemFocus
endstruc

; -note that the type of scroll bar, vertical or horizontal, is determined by
;  checking the GuiObj.Height. if the height is greater than the width, it is
;  vertical, else it is horizontal. it uses only one item type, instead of two
;  separate item types like with Visual Basic.
; -this scroll bar works differently than most. instead of two small arrow
;  buttons, just click anywhere on either side of the bar to scroll that
;  direction. to scroll by a page, right click. to instantly jump to any spot
;  double click on it and the bar will move there. like any other scroll bar,
;  you can grab it and drag it to where you want it.
; -generates message when its value is changed.
%endif

%ifdef UseLabelCode
;컴컴컴컴컴컴컴컴컴컴
struc LabelObj
.TextPtr:       resd 1          ;string is not null terminated
.TextLen:       resd 1          ;number of characters in text
.Flags:         resd 1
 .AlignLeft     equ 0           ;characters start from the left column
 .AlignRight    equ 1           ;characters align to right column
 .AlignCenter   equ 2           ;length of string is centered
 .AlignMask     equ 3
 .BlockLeft     equ 0           ;keep characters on left side visible
 .BlockRight    equ 4           ;keep characters on right side visible
 .BlockCenter   equ 8           ;do not allow text to extend either direction off the screen, wrap both sides
 .BlockMask     equ 12

.DefFlags    equ GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.NoMouseFocus
endstruc

; -Alignment can be left/center/right combined with left/right clipping. For
;  example, a complete path and filename would normally be left aligned when
;  less than the maximum width, but since you would always want to be able to
;  see the rightmost part of the path, it would also be right blocked.
;  On some labels you would want to always see both sides of the text, rather
;  than having text extend off the label being clipped, so it can also be
;  word-wrapped.
; -No messages.
%endif

%ifdef UseImageCode
;컴컴컴컴컴컴컴컴컴컴
struc ImageObj
.ImagePtr:      resd 1
.Flags:         resd 1
 .Scale         equ 1           ;image should be scaled
 .Transparent   equ 2           ;a color in the image is transparent

.DefFlags    equ GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.NoMouseFocus
endstruc
%endif

%ifdef UseBorderCode
;컴컴컴컴컴컴컴컴컴컴
struc BorderObj
.DefFlags    equ GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.NoMouseFocus
;(nothing else for now)
endstruc
%endif

%ifdef UseButtonCode
;컴컴컴컴컴컴컴컴컴컴
struc ButtonObj
.TextPtr:       resd 1          ;string is not null terminated
.TextLen:       resd 1          ;number of characters in text
.Value:         resb 1          ;out, pressed in, checked, or selected
 .Pressed       equ 1
 .Toggle        equ 2
 .Lock          equ 4

.DefFlags    equ GuiObj.DefFlags
endstruc

;(PushButton)
; -generates messages when either pushed or released.
;(CheckButton)
; -generates message when its value is changed.
;(SelectButton)
; -same a check button, except for looks, and the fact that it is always part
;  of a group, so only one can be selected at a time.
; -generates message when its value is changed.
%endif

%ifdef UseAtrListCode
;컴컴컴컴컴컴컴컴컴컴
; Attribute list
struc AtrListObj
.TotalItems:    resb 1          ;total attributes in list (including invisible ones)
.Rows:          resb 1          ;number of visible attributes
.PageRows:      resb 1          ;rows visible per page (item height/8)
.NamesWidth:    resb 1          ;amount of column spacing for name
.Selected:      resb 1          ;selected attribute item
.Scroll:        resb 1          ;base attribute item of list's top
alignb 4
.ScrollHandle:  resd 1          ;ptr to sibling scroll bar item
;컴컴컴컴
.Items:
.NamePtr:       resd 1          ;ptr to attribute name
.NameLen:       resd 1          ;number of characters in name
.TextPtr:       resd 1          ;ptr to picture or string, depending on type
.TextLen:       resd 1          ;number of characters in attribute text
.Flags:         resd 1
 .KeyNum        equ 1           ;preview all numeric keypresses
 .KeyNumB       equ 0
 .KeyBkSpc      equ 2
 .KeyBkSpcB     equ 1
 .KeyNormalDec  equ 4           ;preview value change keypresses
 .KeyNormalDecB equ 2
 .KeyNormalInc  equ 8
 .KeyNormalIncB equ 3
 .KeySmallDec   equ 16
 .KeySmallDecB  equ 4
 .KeySmallInc   equ 32
 .KeySmallIncB  equ 5
 .KeyLargeDec   equ 64
 .KeyLargeDecB  equ 6
 .KeyLargeInc   equ 128
 .KeyLargeIncB  equ 7
 .KeyMin        equ 256
 .KeyMinB       equ 8
 .KeyMax        equ 512
 .KeyMaxB       equ 9
 .Hidden        equ 1024        ;attribute exists but not shown
 .IsPicture     equ 2048        ;type text/picture
 .Redraw        equ 4096        ;attribute value has been changed or selected
 .Redrawb       equ 12          ;attribute value has been changed or selected
 .GetValue      equ 8192        ;needs name/value strings from owner (sends .GetValue message)
 .Disabled      equ 16384       ;value can not be changed
 .Dimmed        equ 32768       ;can not be selected, activated, or changed
.Value:         resd 1          ;attribute's current value
.Min:           resd 1          ;lowest value        Home
.Max:           resd 1          ;highest value       End
.SmallStep:     resd 1          ;smallest step       Shift+(L/R)  OR  + -
.NormalStep:    resd 1          ;normal step         Left Right
.LargeStep:     resd 1          ;largest step        Ctrl+(L/R)   OR  * /
.Items_size     equ $-.Items    ;size of each entry in container list

.DefFlags    equ GuiObj.DefFlags
endstruc

; -the item name/description is always text.
; -the value can be displayed by text or a picture
; -generates messages whenever a value is changed, certain editing keys are
;  pressed (if the owner needs to preview them), Enter is pressed or mouse
;  clicked, or a different attribute is selected.
%endif

%assign UseFlag 0               ;'ifdef' doesn't accept ||
%ifdef UseAtrBarCode
  %assign UseFlag 1
%elifdef UseTabStripCode
  %assign UseFlag 1
%endif

%if UseFlag
;컴컴컴컴컴컴컴컴컴컴
; Tab strip
struc TabStripObj
.TotalItems:    resb 1          ;total tabs in strip (including invisible ones)
.Selected:      resb 1          ;selected tab
.Hovered:       resb 1          ;tab last hovered over
                alignb 4
;컴컴컴컴
.Items:
.TextPtr:       resd 1          ;ptr to tab name (or picture)
.TextLen:       resd 1          ;number of characters in name
.Flags:         resb 1
 .Hidden        equ 1
 .IsPicture     equ 2           ;type text/picture
 .Redraw        equ 4           ;tab has been changed or selected
 .Redrawb       equ 2           ;redraw bit
 .Separator     equ 8           ;tab is separated
 .Disabled      equ 16          ;tab can not be selected
 .Marked        equ 32          ;specially drawn
.Width:                         ;tab width in pixels
.Height:        resb 1          ;horizontal synonym
                alignb 4
.ItemsSizeOf    equ $-.Items    ;size of each entry in container list

.DefFlags    equ GuiObj.DefFlags|GuiObj.NoKeyFocus|GuiObj.FixedPosition|GuiObj.FixedLayer
endstruc

; -this same structure used both by attribute bars found at the bottom of the
;  screen and tab strips on the left of the screen.
; -the tab/atr name is usually text, but may also be a picture
; -generates messages whenever a tab/attribute is hovered over or clicked on.
%endif

%ifdef UseEmbedMenuCode
  %define UseMenuCode
%elifdef UseFloatMenuCode
  %define UseMenuCode
%endif

%ifdef UseMenuCode
;컴컴컴컴컴컴컴컴컴컴
; This structure is fairly small because most information is stored in the
; menu lists.
struc MenuObj
.MenuList:      resd 1          ;menu ptr at top level
.Selected:      resd 1          ;MenuList ptr currently selected
.Sibling:       resd 1          ;ptr in chain to next menu object (if any)
.SelIndex:      resw 1          ;index of selected choice
endstruc

; Every choice can has both a text string and image. All choices have a
; globally unique id that can range 0-65535. The choice limit is 255.
struc MenuListObj
.Creator:       resd 1          ;code address to initialize menu
.Container:     resd 1          ;menu object that is showing MenuList (if any)
.Child:         resd 1          ;ptr to child MenuList (if opened)
.TotalItems:    resb 1          ;total choices in menu (0-255)
.Selected:      resb 1          ;selected choice (0-254, -1 if none selected)
.Opened:        resb 1          ;opened choice (-1 if none open)
.ChangeCount:   resb 1          ;counts number of changes to menu
.Size:
.Height:        resw 1          ;pixel height of whole menu
.Width:         resw 1          ;including any accumulated open child height
.ChildPos:
.ChildTop:      resw 1          ;top of child MenuList, relative to container
.ChildLeft:     resw 1          ;ALWAYS unsigned
;컴컴컴컴
.Items:
.ImagePtr:      resd 1          ;ptr to picture
.TextPtr:       resd 1          ;ptr to choice text (null ended)
.Submenu:       resd 1          ;ptr to choice's submenu list
.Flags:
 .Hidden        equ 1 <<16      ;invisible choice
 .Redraw        equ 4 <<16      ;menu has been changed or selected
 .Redrawb       equ 2 +16       ;redraw bit
 .Separator     equ 8 <<16      ;choice is separated
 .Disabled      equ 16<<16      ;menu can not be selected
 .Marked        equ 32<<16      ;choice is marked
 .Opens         equ 64<<16      ;opens a branching MenuList
 .Redrawn       equ 128<<16     ;submenu has been redrawn since last change
.Index:         resd 1
.ItemsSizeOf    equ $-.Items    ;size of each entry in container list
.ItemsSizeShl   equ 4
endstruc

EmbedMenuObj:
.DefFlags    equ GuiObj.DefFlags

FloatMenuObj:
.DefFlags    equ GuiObj.DefFlags|GuiObj.GroupStart|GuiObj.FixedPosition|GuiObj.FixedLayer|GuiObj.Hidden|GuiObj.Disabled|GuiObj.NoItemFocus
.AlignCol       equ 1           ;set alone will center horizontally
.AlignLeft      equ 2
.AlignRight     equ 4
.AlignWidth     equ 8
.AlignRow       equ 16          ;set alone will center vertically
.AlignTop       equ 32
.AlignBtm       equ 64
.AlignHeight    equ 128

%assign MenuIdx 0

; -there is a big difference between the menu object and the MenuList
;  structure. the structure is simply used by other objects. the menu object
;  is what interprets the mouse & key input and modifies the MenuList
;  variables accordingly.
; -each MenuList has a pointer to its open child (if it currently has one),
;  but no pointer to its parent, because retreating back up the menu chain
;  can be achieved by simply starting from the top of the heirarchy and going
;  down.
; -any changes can be made to a closed MenuList structure (like disabling,
;  hiding, changing the text of choices), but if the MenuList is currently
;  being shown/used in any menu object, that container menu must be informed
;  via message that one of its open MenuLists has been modified. That way, the
;  menu object can reformat/resize/redraw/reselect it as needed.

%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Other data structures
;컴컴컴컴컴컴컴컴컴컴
ImageStruct:
;.Bits          resb 1  (not used because all graphics routines are 8bit)
.TransColor     equ -5          ;transparent color index in image
.Size           equ -4
.Height         equ -4
.Width          equ -2
.Pixels         equ 0


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Macros
;컴컴컴컴컴컴컴컴컴컴

; InitGui
; GuiLoop
; DeinitGui
; DefGuiObj
; DefOwnerCallback
; DefWindow
; DefContainedItem
; ...

%define aligndd times ($$-$)&3 db 0

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; The init routine initializes the mouse and all items.
; ! expects that the Main Window ptr is already pushed on the stack
;
; (stack dword MainWindow)
%macro InitGui 0

;컴컴컴컴컴컴컴컴컴�
; Grab keyboard control for ourselves instead of limited BIOS
 %ifdef DosVer
    debugwrite "setting keyboard int handler"
    call SetKeyboardHandler
 %endif

;컴컴컴컴컴컴컴컴컴�
; Initialize mouse
    debugwrite "initializing cursor"

 %ifdef UseGuiCursor
  %ifdef DosVer
    mov eax,21h                 ;mouse driver: software reset
    int 33h
    cmp ax,0FFFFh
    jne .NoMouseDriver
    debugwrite "mouse driver detected"

    ; set threshold speed and waste initial motion counters
    mov [Mouse.NumButtons],bl
    mov eax,13                  ;mouse driver: set threshold speed to minimum
    mov edx,03FFDh
    int 33h
    mov eax,0Bh                 ;mouse driver: read motion counters
    int 33h                     ;simply waste the values
    mov [Cursor.Row],dword Screen.Height/2
    mov [Cursor.Col],dword Screen.Width/2
  %endif

    ; make cursor visible
    call SetCursorImage.Default
    ;DebugMessage "Mouse driver reset"
.NoMouseDriver:
  %ifndef UseDisplayBuffer
    ;call GrabCursorImage
  %endif
 %endif

;컴컴컴컴컴컴컴컴컴�
; Initialize timer

 %ifndef NoGuiTimerHandler
 %ifdef WinVer
    debugwrite "setting windows timer = 30hz"
    api SetTimer,[hwnd],1,33,NULL   ;30 times per second, no callback
    debugwrite "set timer result %d",eax
 %elifdef DosVer
    debugwrite "setting timer int handler, PIT rate = 30hz"
    ; save existing interrupt handler
    mov eax,0204h               ;get protected-mode interrupt
    mov bl,8                    ;timer interrupt
    int 31h
    mov [Timer.HandlerOfs],edx  ;save offset
    mov [Timer.HandlerSel],ecx  ;save selector

    ; set the GUI's handler
    mov eax,0205h               ;set protected mode interrupt
    mov ecx,cs                  ;pass our code selector
    mov edx,GuiTimerHandler
    mov bl,8                    ;timer interrupt
    int 31h

    ; increase rate to more precise rate of 30hz rather than only 18.2
    ;mov cx,39772               ;1193182/30=39772.7 (1.1931817MHz / 30hz)
    mov ecx,39600               ;this value seems to sync better
    call SetPitRate
 %endif
 %endif

;컴컴컴컴컴컴컴컴컴�
; Initialize all items
    debugwrite "creating all GUI items"
    or dword [GuiFlags],GuiFlags.Active
    mov eax,Msg.Created
    call SendMsgAllItems
    debugwrite "setting initial item focus"
    call SetItemFocus.OfActive

%endmacro


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; The deinit routine kills the timer, keyboard handler, and all items.
; ! expects that the Main Window ptr is pushed on the stack
;
; (stack dword MainWindow)
%macro DeinitGui 0

;컴컴컴컴컴컴컴컴컴�
 %ifndef NoGuiTimerHandler
 %ifdef WinVer
    debugwrite "killing windows timer"
    api KillTimer,[hwnd],1      ;destroy 30 tick per second timer
 %elifdef DosVer
    debugwrite "restoring timer int handler, PIT rate = 18.2hz"
    ;restore default rate of 18.2065hz
    xor ecx,ecx
    call SetPitRate

    ; restore the BIOS/DOS timer vector
    mov eax,0205h               ;set protected mode interrupt
    mov edx,[Timer.HandlerOfs]  ;get offset
    mov ecx,[Timer.HandlerSel]  ;get selector
    mov bl,8                    ;timer interrupt
    int 31h
 %endif
 %endif

;컴컴컴컴컴컴컴컴컴�
; Destroy all items
    debugwrite "destroying all GUI items"
    mov eax,Msg.Destroyed
    call SendMsgAllItems
    and dword [GuiFlags],~GuiFlags.Active

;컴컴컴컴컴컴컴컴컴�
 %ifdef WinVer
    api ClipCursor, NULL
 %endif

;컴컴컴컴컴컴컴컴컴�
; Restore keyboard control to limited BIOS
 %ifdef DosVer
    debugwrite "restoring keyboard int handler"
    call RestoreKeyboardHandler
 %endif

 %ifdef WinVer
    ; although the window is automatically destroyed when the process dies,
    ; it is better to destroy it before that so that memory is more reliably
    ; freed and so that key focus is set to the next window - not taskbar.
    debugwrite "destroying main GUI window"
    api DestroyWindow, [hwnd]
 %endif
%endmacro


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Creates the main GUI window.
; Sets hwnd, hdc
%macro CreateGuiWin 0
    api LoadIcon, Program.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax

    ; create invisible cursor
    ; Since the GUI uses its own custom cursors, which are simultaneously
    ; drawn with the rest of the display buffer, there is no cursor flicker
    ; or disjointed object/cursor movement.
    sub esp,256
    xor eax,eax
    mov edi,esp
    mov ecx,128/4
    push edi                    ;pass xor mask param
    ;cld
    rep stosd
    push edi                    ;pass and mask param
    mov eax,0FFFFFFFFh
    mov ecx,128/4
    rep stosd
    api CreateCursor, Program.BaseAddress,0,0, 32,32 ;, edi,esp
    add esp,256
    ;api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, wc
    debugwrite "register result=%X", eax
    test eax,eax
    mov esi,%%PuiErrMsgWinReg
    jz near GuiErrMsgEnd

    ; create instance of window
    ;api AdjustWindowRect, rect,WS_CAPTION|WS_POPUP|WS_MINIMIZEBOX|WS_SYSMENU|WS_VISIBLE, FALSE
    ;mov edx,[rect+RECT.bottom]
    ;mov ecx,[rect+RECT.right]
    ;sub edx,[rect+RECT.top]
    ;sub ecx,[rect+RECT.left]
    ;debugwrite "creating window %dx%d",ecx,edx
    ;api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_APPWINDOW, Program.Class, Program.Title, WS_CAPTION|WS_MINIMIZEBOX|WS_POPUP|WS_SYSMENU|WS_VISIBLE, 100,100, ecx,edx, NULL, NULL, Program.BaseAddress, NULL

    xor eax,eax
    api SystemParametersInfo, SPI_GETWORKAREA, eax,rect, eax
    mov edx,[rect+RECT.bottom]
    mov ecx,[rect+RECT.right]
    sub edx,[rect+RECT.top]         ;get height
    sub ecx,[rect+RECT.left]        ;get width
    sub edx,Screen.Height
    sub ecx,Screen.Width
    shr edx,1
    shr ecx,1
    add edx,[rect+RECT.top]
    add ecx,[rect+RECT.left]
    ;api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_APPWINDOW, Program.Class, Program.Title, WS_POPUP|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX, ecx,edx, Screen.Width,Screen.Height,NULL, NULL, Program.BaseAddress, NULL
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_APPWINDOW, Program.Class, Program.Title, WS_POPUP|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX, ecx,edx, Screen.Width,Screen.Height,NULL, NULL, Program.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    mov esi,%%PuiErrMsgWinCreate
    jz near GuiErrMsgEnd
    mov [hwnd],eax

    ;! Any window procedure must return FALSE on the WM_NCCALCSIZE message.
    ;  The window is created with the WS_CAPTION style set so that dumb
    ;  Explorer will minimize it when Minimize All is chosen. However, this
    ;  means the window will be given an annoying title bar, regardless of if
    ;  WS_POPUP is also set. So the WM_NCCALCSIZE must be handled to prevent
    ;  Windows from messing with the client area.
    ;  The procedure should also respond FALSE to NCPAINT (not WM_NCACTIVATE),
    ;  and return TRUE for WM_NCHITTEST, since it seems Windows sometimes
    ;  bypasses its own proper painting process and draws unexpectedly.
    ;! To prevent any possible redraw flicker, return true on WM_ERASEBKGND.
    api GetDC, eax              ;get window class display handle
    debugwrite "get hdc=%X",eax
    mov [hdc],eax

    ;api GetCurrentThreadId
    ;mov [tid],eax

[section text]
%%PuiErrMsgWinReg: db "Could not register main window!? (RegisterClass)",0
%%PuiErrMsgWinCreate: db "Could not create main window!? (CreateWindowEx)",0
__SECT__
%endmacro


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
%macro DebugMessage 1
 %if GuiDebugMode & 1
  %ifstr %1
    [section text]
    %%DebugMsg: db %1,0
    __SECT__
    push dword %%DebugMsg
  %else
    push dword %1
  %endif
    call PrintDebugMessage
 %endif
%endmacro

%macro DebugOwnerMsg 1
 %if GuiDebugMode & 32
  %ifstr %1
    [section text]
    %%DebugMsg: db %1,0
    __SECT__
    push dword %%DebugMsg
  %else
    push dword %1
  %endif
    call PrintDebugMessage
 %endif
%endmacro

%if GuiDebugMode & 2
    %define DrawItemOverlay call DebugObjCode.DrawOverlay
%else
    %define DrawItemOverlay
%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
%macro StartMsgJtbl 0
align 4,db 0
.MsgTable:
    %assign JtblHigh -256
%endmacro

%macro AddMsgJtbl 2
  %assign JtblValue %1-128^-128
  %if JtblHigh <= -256
    %assign JtblLow JtblValue
    %assign JtblHigh JtblValue
  %endif
  %if JtblValue < JtblHigh
    %error "Jump table index out of order"
  %else
    times JtblValue-JtblHigh  dd .IgnoreMsg
    %assign JtblHigh JtblValue+1
    dd %2
  %endif
%endmacro

%macro UseMsgJtbl 0
  %if JtblLow=0
    cmp al,JtblHigh
    jae .IgnoreMsg              ;ignore message if unrecognized
    movzx edx,al                ;get low byte of message
  %else
    movzx edx,al                ;get low byte of message
    sub dl,JtblLow
    cmp dl,JtblHigh-JtblLow
    jae .IgnoreMsg              ;ignore message if unrecognized
  %endif
    jmp dword [.MsgTable+edx*4]
.IgnoreMsg:
    stc
    ret
%endmacro

; UIJtbl = unsigned integer jump table
; (name of table,
;  name of ignore sub)
%macro StartUIJtbl 2
align 4,db 0
%1:
    %assign JtblHigh 0
    %define JtblIgnoreSub %2
%endmacro

%macro AddUIJtbl 2
  %if %1 >= JtblHigh
    times %1-JtblHigh  dd JtblIgnoreSub
    %assign JtblHigh %1+1
    dd %2
  %else
    %error "Jump table index out of order"
  %endif
%endmacro

;(callback structure label
; callback code address)
%macro DefOwnerCallback 2
    align 4, db 0
    dd %2
CallBack_%1:
%endmacro


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
;(name,
; item code,
; owner code,
; flags,
; top,
; left,
; height,
; width)
%macro DefItem 8
    align 4, db 0
    dw %5,%6                    ;offset of object within parent window,
    dw %7,%8                    ;size in pixels (not stupid twips)
    dw %{1}.Idx                 ;item index in container
    dw 0                        ;reserved for now
    dd %4                       ;flags to determine object behaviour (invisible, disabled, gets focus, mouse responsive, needs redrawing)
    dd %{1}.Gic                 ;ptr to containing window's gui entry
    dd %3                       ;owner callback
    dd %2                       ;item message handler (or intercepting code)
    %assign GuiObjHeight %7
    %assign GuiObjWidth  %8
    %define GuiObjName   %1
%1:
%endmacro


;(active key item,
; background color/bitmap ptr,
; flags)
%macro DefWindow 3
    dw .TotalItems,.TotalItems   ;total items, max items
    dd %1,NullGuiItem,NullGuiItem;active item, no key or cursor item
    dw 32767,32767,-32768,-32768 ;empty mouse top/left/bottom/right
    dw -32768,-32768,32767,32767 ;full redraw portion
    dd %2,%3                     ;background info, flags
    %define ContainerMaxItems .TotalItems
    %assign GuiItemIdx 0
%endmacro


;(max items,
; active item,
; background color/bitmap ptr,
; flags)
%macro DefWindow 4
    dw .TotalItems,%1            ;total items, max items
    dd %2,NullGuiItem,NullGuiItem;active item, no key or cursor item
    dw 32767,32767,-32768,-32768 ;empty mouse top/left/bottom/right
    dw -32768,-32768,32767,32767 ;full redraw portion
    dd %3,%4                     ;background info, flags
    %define ContainerMaxItems %1
    %assign GuiItemIdx 0
%endmacro


%macro DefContainedItem 1
    dd %1                       ;gui item data ptr
    dw GuiItemIdx               ;zlayer order for mouse
    dw GuiItemIdx               ;tab order for keyboard
    %{1}.Idx equ GuiItemIdx
    %{1}.Gic equ GuiObjName     ;name of previous item (window most likely)
    %assign GuiItemIdx GuiItemIdx+1
%endmacro


%macro DefContainedItemNoEqu 1
    dd %1                       ;gui item data ptr
    dw GuiItemIdx               ;zlayer order for mouse
    dw GuiItemIdx               ;tab order for keyboard
    %assign GuiItemIdx GuiItemIdx+1
%endmacro


%macro DefWindowEnd 0
    .TotalItems     equ GuiItemIdx
    %if ContainerMaxItems<GuiItemIdx
      %error "container holds more items than max allowed"
    %endif
    times (ContainerMaxItems-GuiItemIdx)*WindowObjItems.SizeOf db 0
%endmacro


;(text ptr, text len, button state)
%macro DefPushButton 3
    dd %1                       ;text ptr
    dd %2                       ;text length
    db %3                       ;out, pressed in, checked, or selected
%endmacro


;(text ptr, text len, buttons to include)
%macro DefTitleBar 3
    dd %1                       ;text ptr
    dd %2                       ;text length
    db %3                       ;flags
%endmacro


;(text ptr, text len, alignment)
%macro DefLabel 3
    dd %1                       ;text ptr
    dd %2                       ;number of characters in text
    dd %3                       ;alignment
%endmacro


;(image ptr, image flags)
%macro DefImage 2
    dd %1                       ;image dimensions ptr
    dd %2                       ;flags
%endmacro


;(text ptr, text len, max len, alignment/flags)
%macro DefTextPrompt 4
    dd %1                       ;text ptr
    dd %2                       ;number of characters in text
  %if %3 = 0
    dd %2                       ;set max characters to text length
  %else
    dd %3                       ;maximum number of characters allowed.
  %endif
    dd %2                       ;character position of cursor
    dw 0,%2                     ;cursor row/col
    dd %2                       ;character position of selection start
    dw 0,%2                     ;selection row/col
    dd 0                        ;character position of text scroll
    dw 0,0                      ;scroll top row/left col
    dd %4                       ;alignment/flags
%endmacro


;(sibling scroll bar)
%macro DefAtrList 1
    db .TotalItems              ;total attributes in list (including invisible ones)
    db .TotalItems              ;number of visible attributes
    db GuiObjHeight/FontDefHeight ;rows visible per page (item height/8)
  %ifdef UseSmallScreen
    db 40                       ;amount of column spacing for name
  %else
    db 80                       ;amount of column spacing for name
  %endif
    db 0                        ;selected attribute item
    db 0                        ;scroll position (attribute item at list's top)
    align 4, db 0
    dd %1                       ;ptr to sibling scroll bar item
    %assign GuiItemIdx 0
%endmacro


;(name id,
; name string ptr,
; name string len,
; atr ptr,
; atr len,
; flags,
; value,
; low range,
; high range,
; small step,
; typical step,
; large step)
%macro DefAtrListItem 12
  %ifid %1
    %1 equ GuiItemIdx
    %1Ptr equ GuiObjName + GuiItemIdx*AtrListObj.Items_size
  %endif
    dd %2                       ;ptr to attribute name
    dd %3                       ;number of characters in name
    dd %4                       ;ptr to picture or string, depending on type
    dd %5                       ;number of characters in attribute text
    dd %6|AtrListObj.GetValue   ;flags
    dd %7                       ;attribute's current value
    dd %8                       ;lowest value        Home
    dd %9                       ;highest value       End
    dd %10                      ;smallest increment  Shift+(L/R)  OR  + -
    dd %11                      ;typical increment   Left Right
    dd %12                      ;largest increment   Ctrl+(L/R)   OR  * /
    %assign GuiItemIdx GuiItemIdx+1
%endmacro


%macro DefAtrListEnd 0
    .TotalItems equ GuiItemIdx  ;total attributes in list (including invisible ones)
%endmacro


;()
%macro DefTabStrip 0
    db .TotalItems              ;total tabs in bar (including invisible ones)
    db 0                        ;selected tab/attribute
    db 0                        ;hovered tab/attribute
    db 0                        ;alignment
    %assign GuiItemIdx 0
%endmacro

%define DefAtrBar DefTabStrip


;(name ptr,
; name len,
; flags,
; width)
%macro DefTabStripItem 4
    dd %1                       ;ptr to name
    dd %2                       ;number of characters in name
    db %3                       ;flags
    db %4                       ;height/width
    align 4, db 0
    %assign GuiItemIdx GuiItemIdx+1
%endmacro

%define DefAtrBarItem DefTabStripItem


%macro DefTabStripEnd 0
    .TotalItems equ GuiItemIdx  ;total attributes in list (including invisible ones)
%endmacro

%define DefAtrBarEnd DefTabStripEnd


;(range,
; value,
; base,
; small step,
; large step)
%macro DefScrollHandle 5
    dd %1                       ;maximum value, total range of values
    dd %2                       ;current value (0 to Range-1)
    dd %3                       ;base value to add to value (in case range does not start at 0)
    dd %4                       ;how much to scroll when left-clicking (row)
    dd %5                       ;how much to scroll when right-clicking (page)
    dd 66                       ;scroll speed
%endmacro


;(label name,
; height,
; width)
%macro DefImageStruct 3
    dw %2,%3                    ;height & width
%1:
%endmacro


;(label name,
; height,
; width,
; transparent color)
%macro DefImageStruct 4
    db %4                       ;transparent color
    dw %2,%3                    ;height & width
%1:
    ;image pixels go here...
%endmacro


;(MenuList ptr)
%macro DefMenuObj 1
    dd %1                       ;MenuList ptr at heirarchy top level
    dd %1                       ;MenuList ptr currently selected
    dd GuiObjName               ;ptr in chain to next menu object (if any, by default points to itself)
    dw 0                        ;index of selected choice
%endmacro


;(MenuList name,
; MenuList initialization code)
%macro DefMenuList 2
    align 4, db 0
%1:
    dd %2                       ;code address to initialize menu
    dd 0                        ;menu object that is showing MenuList (none for now)
    dd 0                        ;ptr to child MenuList (no child yet)
    db .TotalItems              ;total choices in menu (0-255)
    db 0                        ;selected choice (0-254)
    db 255                      ;opened choice (none open yet)
    db 0                        ;counts number of changes to menu
    dw .TotalItems*8            ;pixel height of whole menu (recalculated by code before showing menu)
    dw 64                       ;width
    dw 0                        ;top of child menu, relative to container
  %ifdef UseSmallScreen
    dw 8                        ;left
  %else
    dw 16+2                     ;left
  %endif
    %assign GuiItemIdx 0
%endmacro


;(MenuList name,
; MenuList initialization code,
; child MenuList,
; opened choice)
%macro DefMenuList 4
    align 4, db 0
%1:
    dd %2                       ;code address to initialize menu
    dd 0                        ;menu object that is showing MenuList (none for now)
    dd %3                       ;ptr to child MenuList (no child yet)
    db .TotalItems              ;total choices in menu (0-255)
    db 0                        ;selected choice (0-254)
    db %4                       ;opened choice
    db 0                        ;counts number of changes to menu
    dw .TotalItems*8            ;pixel height of whole menu (recalculated by code before showing menu)
    dw 64                       ;width
    dw 0                        ;top of child menu, relative to container
  %ifdef UseSmallScreen
    dw 8                        ;left
  %else
    dw 16+2                     ;left
  %endif
    %assign GuiItemIdx 0
%endmacro


;(id name,
; choice text ptr,
; picture ptr,
; choice flags)
%macro DefMenuListItem 4
  %ifid %1
    %1 equ MenuIdx
    %1Ofs equ GuiItemIdx
  %endif
    dd %3                       ;ptr to picture
  %ifstr %2
[section text]
    %%Text: db %2,0
__SECT__
    dd %%Text                   ;ptr to choice text
  %else
    dd %2                       ;ptr to choice text
  %endif
    dd 0                        ;null MenuList child
    dd MenuIdx | %4             ;choice index | choice flags
    %assign MenuIdx MenuIdx+1
    %assign GuiItemIdx GuiItemIdx+1
%endmacro


;(id name,
; choice text ptr,
; picture ptr,
; choice flags,
; child MenuList ptr)
%macro DefMenuListItem 5
  %ifid %1
    %1 equ MenuIdx
    %1Ofs equ GuiItemIdx
  %endif
    dd %3                       ;ptr to picture
  %ifstr %2
[section text]
    %%Text: db %2,0
__SECT__
    dd %%Text                   ;ptr to choice text
  %else
    dd %2                       ;ptr to choice text
  %endif
    dd %5                       ;MenuList child ptr
    dd MenuIdx | %4             ;choice index | choice flags
    %assign MenuIdx MenuIdx+1
    %assign GuiItemIdx GuiItemIdx+1
%endmacro


%macro DefMenuListEnd 0
    .TotalItems equ GuiItemIdx  ;total attributes in list (including invisible ones)
%endmacro


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Miscellaneous
;컴컴컴컴컴컴컴컴컴컴
TickCountPtr equ 46Ch

;컴컴컴컴컴컴컴컴컴컴
; Virtual key codes
VK_LBUTTON         equ 0x01
VK_RBUTTON         equ 0x02
VK_CANCEL          equ 0x03
VK_MBUTTON         equ 0x04
;                      0x05-0x07  Undefined
VK_BACK            equ 0x08
VK_TAB             equ 0x09
;                      0x0A-0x0B  Undefined
VK_CLEAR           equ 0x0C
VK_RETURN          equ 0x0D
VK_ENTER           equ 0x0D ;I've seen far more keyboards with 'Enter'
;                      0x0E-0x0F  Undefined
VK_SHIFT           equ 0x10
VK_CONTROL         equ 0x11
VK_MENU            equ 0x12
VK_PAUSE           equ 0x13
VK_CAPITAL         equ 0x14
VK_KANA            equ 0x15
VK_HANGUL          equ 0x15
VK_JUNJA           equ 0x17
VK_FINAL           equ 0x18
VK_HANJA           equ 0x19
VK_KANJI           equ 0x19
;                      0x1A       Undefined
VK_ESCAPE          equ 0x1B

VK_CONVERT         equ 0x1C
VK_NONCONVERT      equ 0x1D
VK_ACCEPT          equ 0x1E
VK_MODECHANGE      equ 0x1F
VK_SPACE           equ 0x20
VK_PRIOR           equ 0x21
VK_PAGEUP          equ 0x21 ;more familiar keyname
VK_NEXT            equ 0x22
VK_PAGEDOWN        equ 0x22 ;more familiar keyname
VK_END             equ 0x23
VK_HOME            equ 0x24
VK_LEFT            equ 0x25
VK_UP              equ 0x26
VK_RIGHT           equ 0x27
VK_DOWN            equ 0x28
VK_SELECT          equ 0x29
VK_PRINT           equ 0x2A ; OEM specific in Windows 3.1 SDK
VK_EXECUTE         equ 0x2B
VK_SNAPSHOT        equ 0x2C
VK_INSERT          equ 0x2D
VK_DELETE          equ 0x2E
VK_HELP            equ 0x2F
VK_0               equ 0x30
VK_1               equ 0x31
VK_2               equ 0x32
VK_3               equ 0x33
VK_4               equ 0x34
VK_5               equ 0x35
VK_6               equ 0x36
VK_7               equ 0x37
VK_8               equ 0x38
VK_9               equ 0x39
;                      0x3A-0x40  Undefined
VK_A               equ 0x41
VK_B               equ 0x42
VK_C               equ 0x43
VK_D               equ 0x44
VK_E               equ 0x45
VK_F               equ 0x46
VK_G               equ 0x47
VK_H               equ 0x48
VK_I               equ 0x49
VK_J               equ 0x4A
VK_K               equ 0x4B
VK_L               equ 0x4C
VK_M               equ 0x4D
VK_N               equ 0x4E
VK_O               equ 0x4F
VK_P               equ 0x50
VK_Q               equ 0x51
VK_R               equ 0x52
VK_S               equ 0x53
VK_T               equ 0x54
VK_U               equ 0x55
VK_V               equ 0x56
VK_W               equ 0x57
VK_X               equ 0x58
VK_Y               equ 0x59
VK_Z               equ 0x5A

VK_LWIN            equ 0x5B
VK_RWIN            equ 0x5C
VK_APPS            equ 0x5D
;                      0x5E-0x5F Unassigned
VK_NUMPAD0         equ 0x60
VK_NUMPAD1         equ 0x61
VK_NUMPAD2         equ 0x62
VK_NUMPAD3         equ 0x63
VK_NUMPAD4         equ 0x64
VK_NUMPAD5         equ 0x65
VK_NUMPAD6         equ 0x66
VK_NUMPAD7         equ 0x67
VK_NUMPAD8         equ 0x68
VK_NUMPAD9         equ 0x69
VK_MULTIPLY        equ 0x6A
VK_ADD             equ 0x6B
VK_SEPARATOR       equ 0x6C
VK_SUBTRACT        equ 0x6D
VK_DECIMAL         equ 0x6E
VK_DIVIDE          equ 0x6F
VK_F1              equ 0x70
VK_F2              equ 0x71
VK_F3              equ 0x72
VK_F4              equ 0x73
VK_F5              equ 0x74
VK_F6              equ 0x75
VK_F7              equ 0x76
VK_F8              equ 0x77
VK_F9              equ 0x78
VK_F10             equ 0x79
VK_F11             equ 0x7A
VK_F12             equ 0x7B
VK_F13             equ 0x7C
VK_F14             equ 0x7D
VK_F15             equ 0x7E
VK_F16             equ 0x7F
VK_F17             equ 0x80
VK_F18             equ 0x81
VK_F19             equ 0x82
VK_F20             equ 0x83
VK_F21             equ 0x84
VK_F22             equ 0x85
VK_F23             equ 0x86
VK_F24             equ 0x87
;                      0x88-0x8F  Unassigned

VK_NUMLOCK         equ 0x90
VK_SCROLL          equ 0x91
;                      0x92-0x9F  Unassigned
VK_LSHIFT          equ 0xA0 ; differencing between right and left
VK_RSHIFT          equ 0xA1 ; shift/control/alt key. Used only by
VK_LCONTROL        equ 0xA2 ; GetAsyncKeyState() and GetKeyState().
VK_RCONTROL        equ 0xA3
VK_LMENU           equ 0xA4
VK_RMENU           equ 0xA5
;                      0xA6-0xB9  Unassigned

; note that I redefined a few of the constants below for more familiar names
; on the standard 101 keyboard
VK_OEM_1           equ 0xBA
VK_COLON           equ 0xBA
VK_OEM_PLUS        equ 0xBB
VK_PLUS            equ 0xBB
VK_OEM_COMMA       equ 0xBC
VK_COMMA           equ 0xBC
VK_OEM_MINUS       equ 0xBD
VK_MINUS           equ 0xBD
VK_OEM_PERIOD      equ 0xBE
VK_PERIOD          equ 0xBE
VK_OEM_2           equ 0xBF
VK_OEM_3           equ 0xC0
VK_TILDE           equ 0xC0
;                      0xC1-0xDA  Unassigned
VK_OEM_4           equ 0xDB
VK_LBRACKET        equ 0xDB
VK_OEM_5           equ 0xDC
VK_SLASH           equ 0xDC
VK_OEM_6           equ 0xDD
VK_RBRACKET        equ 0xDD
VK_OEM_7           equ 0xDE
VK_QUOTE           equ 0xDE
;                      0xDF-0xE4  OEM specific
VK_PROCESSKEY      equ 0xE5
;                      0xE6       OEM specific
;                      0xE7-0xE8  Unassigned
;                      0xE9-0xF5  OEM specific

VK_ATTN            equ 0xF6
VK_CRSEL           equ 0xF7
VK_EXSEL           equ 0xF8
VK_EREOF           equ 0xF9
VK_PLAY            equ 0xFA
VK_ZOOM            equ 0xFB
VK_NONAME          equ 0xFC
VK_PA1             equ 0xFD
VK_OEM_CLEAR       equ 0xFE

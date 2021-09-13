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

/** Summary: About dialog.
*/
static class DlgAboutPlain
{
    static UcWindowFloating dialog;

    public static Uc Create(Uc parent)
    {
        if (dialog == null)
        {
            dialog = new UcWindowFloating(parent, "About Plain", UcWindow.PackerCol, Action);
            new UcImage(dialog, new TextureRectangle(PlainMain.Style, new Rectangle(4, 124, 32, 32), Color.White));
            new UcLabel(dialog, "Piken's Layered Interface\nDwayne Robinson\n2007-07-10");
            //new UcButton(this, "Close", Action);
        }
        dialog.Parent.FocusCapture(dialog);
        return dialog;
    }

    static void Action(Uc uc, UcTitle.Actions action)
    {
        switch (action)
        {
        case UcTitle.Actions.Close:
            dialog.Destroy();
            dialog = null;
            break;
        }
    }
}

}

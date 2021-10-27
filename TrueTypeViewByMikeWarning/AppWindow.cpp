#include "ttview.h"
#include "AppWindow.h"


AppWindow::~AppWindow()
{

}


LRESULT AppWindow::BaseWindowProc(HWND window, UINT message, WPARAM wParam, LPARAM lParam)
{
    AppWindow *_this;

// The definitions for Set/GetWindowLongPtr are broken and it's impossible to
// use them without warnings.  Turn the warnings off temporarily.

#pragma warning (push)
#pragma warning (disable: 4244)
#pragma warning (disable: 4312)

    if (WM_NCCREATE == message)
    {
        _this = (AppWindow *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        SetWindowLongPtr(window, GWLP_USERDATA, (LONG_PTR) _this);
        _this->m_window = window;
    }
    else
    {
        _this = (AppWindow *) GetWindowLongPtr(window, GWLP_USERDATA);
    }

#pragma warning (pop)

    if (NULL != _this)
        return _this->WindowProc(message, wParam, lParam);
    else
        return DefWindowProc(window, message, wParam, lParam);
}

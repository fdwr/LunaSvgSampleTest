class AppWindow
{
protected:

   ~AppWindow();

    HWND m_window;

    virtual LRESULT WindowProc(UINT message, WPARAM wParam, LPARAM lParam) = 0;

    static LRESULT CALLBACK BaseWindowProc(HWND, UINT, WPARAM, LPARAM);
};
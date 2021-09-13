// PikenSoft 2007
// Dwayne Robinson
// TapTempo clone
// inspired from AnalogX TapTempo

#include "precomp.h"
#include "TapTempo.resource.h"

////////////////////////////////////////////////////////////////////////////////

int g_timeBufferSum       = 0;
int g_timeBufferEntries   = 0;
int g_timeBufferLastTick  = 0;
const int ResetThreshold  = 5*1000;

////////////////////////////////////////////////////////////////////////////////

InstanceHandle g_ModuleBase;

intptr_t WinApi MainDialogFunc(      
    WindowHandle hwndDlg,
    uint uMsg,
    WPARAM wParam,
    LPARAM lParam
);
void TriggerTapTempo(WindowHandle dialog, bool shouldReset);
void ClearTime();

////////////////////////////////////////////////////////////////////////////////


int WinApi wWinMain (
    InstanceHandle  currentInstance,
    InstanceHandle  previousInstance,
    ZString         lpCmdLine,
    int cmdShow
    )
{
    g_ModuleBase = currentInstance;
    WindowHandle dialog = CreateDialog(g_ModuleBase, MakeIntResource(1), nullptr, &MainDialogFunc);
    ShowWindow(dialog, ShowWindowCommand::Show);

    Message msg;
    while (GetMessage(&msg, nullptr, 0,0) > 0) { 
        if (msg.message == WindowMessage::KeyDown)
            msg.hwnd = dialog; // forcefully redirect key down messages!

        if (!IsDialogMessage(dialog, &msg)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
    return 0;
}


intptr_t WinApi MainDialogFunc(      
    WindowHandle    dialog,
    uint            message,
    WordParam       wParam,
    LongParam       lParam
)
{
    switch (message)
    {
    case WindowMessage::KeyDown:
        TriggerTapTempo(dialog, wParam == KeyCode::BackSpace);
        return true;

    case WindowMessage::Command:
        switch (wParam)
        {
        case DialogId::Cancel:
            DestroyWindow(dialog);
            return true;
        case DialogId::Ok:
            TriggerTapTempo(dialog, true);
            return true;
        }
        break;

    case WindowMessage::InitializeDialog:
        TriggerTapTempo(dialog, true);
        DefWindowProc(dialog, WindowMessage::SetIcon, true, (LongParam)LoadIcon(g_ModuleBase,MakeIntResource(1)));
        break;

    case WindowMessage::Activate:
        ClearTime();
        break;

    case WindowMessage::Destroy:
        PostQuitMessage(0);
        break;

    }
    return false;
}


void TriggerTapTempo(WindowHandle dialog, bool shouldReset)
{
    if (shouldReset) {
        // clear display
        SetDialogItemText(dialog, IdcTempoPrevious,   L"---");
        SetDialogItemText(dialog, IdcTempoAverage,    L"---");
        SetDialogItemText(dialog, IdcIntervalAverage, L"---");
        ClearTime();
    }
    else {
        // update using difference between last tap
        int currentTick = GetTickCount();
        int tickDif = currentTick - g_timeBufferLastTick;

        if (tickDif >= ResetThreshold) {
            // clear if too much time has elapsed since last call
            ClearTime();
        }
        else if (tickDif > 0) {
            // subtract previous tick dif and add new one
            g_timeBufferSum += tickDif;
            g_timeBufferEntries++;
        }

        if (g_timeBufferEntries > 0 && g_timeBufferSum > 0) {
            // convert from milliseconds to seconds
            float intervalBetweenBeats = float(g_timeBufferSum) / (g_timeBufferEntries * 1000);
            float beatsPerMinute       = (g_timeBufferSum > 0) 
                ? g_timeBufferEntries * 1000 * 60 / float(g_timeBufferSum)
                : 0;

            // display new bpm and interval
            wchar_t buffer[20];
            swprintf_s(buffer, elemsof(buffer), L"%2.2f", intervalBetweenBeats);
                SetDialogItemText(dialog, IdcIntervalAverage, buffer);
            swprintf_s(buffer, elemsof(buffer), L"%2.2f", 1000 * 60 / float(tickDif));
                SetDialogItemText(dialog, IdcTempoPrevious,   buffer);
            swprintf_s(buffer, elemsof(buffer), L"%2.2f", beatsPerMinute);
                SetDialogItemText(dialog, IdcTempoAverage,    buffer);
        }
        else {
            // initial keypress, so no time difference yet
            SetDialogItemText(dialog, IdcTempoPrevious,   L"0");
            SetDialogItemText(dialog, IdcTempoAverage,    L"0");
            SetDialogItemText(dialog, IdcIntervalAverage, L"0");
        }

        g_timeBufferLastTick = currentTick;
    }
}


void ClearTime()
{
    g_timeBufferSum      = 0;
    g_timeBufferEntries  = 0;
    g_timeBufferLastTick = 0;
}

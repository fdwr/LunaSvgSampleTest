========================================================================
    Console Application : LaunchMetroApp Project Overview
========================================================================

Launches a Metro app, by Ashwin Needamangala (Principal Test Lead, Windows)
using IApplicationActivationManager::ActivateApplication and
CoAllowSetForegroundWindow.

Example usage:
  LaunchMetroApp.exe Microsoft.BingNews_8wekyb3d8bbwe!AppexNews
  LaunchMetroApp.exe Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe!App
  LaunchMetroApp.exe FileManager_cw5n1h2txyewy!Microsoft.Windows.FileManager
  LaunchMetroApp.exe Facebook.Facebook_8xx8rvfyw5nnt!App
  LaunchMetroApp.exe Microsoft.Office.Word_8wekyb3d8bbwe!microsoft.word

http://blogs.msdn.com/b/windowsappdev/archive/2012/09/04/automating-the-testing-of-windows-8-apps.aspx


To list all the application id's (AppUserModelId) for installed applications,
start PowerShell and paste:

$installedapps = get-AppxPackage
foreach ($app in $installedapps)
{
    foreach ($id in (Get-AppxPackageManifest $app).package.applications.application.id)
    {
        $app.packagefamilyname + "!" + $id
    }
}

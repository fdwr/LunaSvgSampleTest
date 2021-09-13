Attribute VB_Name = "modVote"
DefLng A-Z
Option Explicit

Private Type OPENFILENAME
    lStructSize As Long
    hwndOwner As Long
    hInstance As Long
    lpstrFilter As String
    lpstrCustomFilter As String
    nMaxCustFilter As Long
    nFilterIndex As Long
    lpstrFile As String
    nMaxFile As Long
    lpstrFileTitle As String
    nMaxFileTitle As Long
    lpstrInitialDir As String
    lpstrTitle As String
    flags As Long
    nFileOffset As Integer
    nFileExtension As Integer
    lpstrDefExt As String
    lCustData As Long
    lpfnHook As Long
    lpTemplateName As String
End Type 'http://www.vbcode.com/asp/showsn.asp?theID=1401

Public Declare Function GetAsyncKeyState Lib "user32" (ByVal vKey As Long) As Integer
Private Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long
Const OFNHideReadOnly = 4, OFNFileMustExist = 4096
Dim ofn As OPENFILENAME


Const DbFileName As String = "SgVote.mdb"
Public Const MaxCandidates = 50    'maximum number of candidates in all positions
Public Const MaxPosCandidates = 10 'maximum number of candidates in a single position
Public Const MaxPositions = 10     'total number of positions to apply for
Public TotalCandidates
Public TotalPositions
Public AppPath As String

Public SgvDb As Database
Public SgvTbl As Recordset
Public SgvErr As Boolean
Public CandidatePics(MaxCandidates - 1) As StdPicture
Public CandidateSids(MaxCandidates - 1) As Long
Public CandidateFnames(MaxCandidates - 1) As String
Public CandidateLnames(MaxCandidates - 1) As String
Public CandidateMsgs(MaxCandidates - 1) As String
Public CandidatePositions(MaxCandidates - 1, MaxPositions - 1) As Boolean
Public CandidateChanged(MaxCandidates - 1) As Boolean
Public PositionNames(MaxPositions - 1) As String
Public PositionDescs(MaxPositions - 1) As String

Public Sub Main()

AppPath = "c:\temp" 'App.Path
If Right(AppPath, 1) <> "\" Then AppPath = AppPath & "\"

frmDbConnect.Show
frmDbConnect.lblProgress.Caption = "Connecting..."
DoEvents

'initialize database object
On Error GoTo DbError
Set SgvDb = OpenDatabase(AppPath & DbFileName)
LoadFromDatabase 'LoadTestData
Unload frmDbConnect
On Error GoTo 0

If GetAsyncKeyState(16) And &H8000 Then
    frmEditCandidates.Show vbModal
Else
    frmVote.Show vbModal
End If
SgvDb.Close

Exit Sub

DbError:
ShowDbError
End Sub

Public Sub LoadDbPic(picHnd As StdPicture)
    Dim FileName As String

    On Error GoTo ErrHandler
    FileName = SgvTbl("Picture")
    If Len(FileName) > 0 Then
        If InStr(FileName, ":") <= 0 And Left(FileName, 2) <> "\\" Then
            FileName = AppPath & FileName
        End If
        Set picHnd = LoadPicture(FileName)
    End If
ErrHandler:
End Sub

Public Sub StoreDbPic(picHnd As StdPicture, FileName As String)
    If picHnd Is Nothing Or picHnd = 0 Then
        FileName = ""
    Else
        SavePicture picHnd, FileName
    End If
    'SgvTbl.Edit
    SgvTbl("Picture") = FileName
    'SgvTbl.Update
End Sub

Public Function GetOpenFile(FileName As String, Filter As String, Title As String, hwnd As Long) As String
    Static Recurse As Boolean, TempFile As String

    If Recurse Then Exit Function
    Recurse = True
    ofn.lStructSize = Len(ofn)
    ofn.hwndOwner = hwnd
    ofn.hInstance = App.hInstance
    ofn.lpstrFilter = Filter
    TempFile = Space$(254)
    Mid(TempFile, 1) = FileName
    ofn.lpstrFile = TempFile
    ofn.nMaxFile = 255
    ofn.lpstrFileTitle = Space$(254)
    ofn.nMaxFileTitle = 255
    ofn.lpstrInitialDir = CurDir
    ofn.lpstrTitle = Title
    ofn.flags = OFNHideReadOnly Or OFNFileMustExist

    If GetOpenFileName(ofn) Then GetOpenFile = Trim(ofn.lpstrFile)
    Recurse = False
End Function


Public Sub LoadFromDatabase()

Dim Value, Count

frmDbConnect.Show
frmDbConnect.lblProgress.Caption = "Reading..."
DoEvents

'read in all candidates and their information
TotalCandidates = 0
On Error GoTo DbError
Set SgvTbl = SgvDb.OpenRecordset("tblPositions")
SgvTbl.Index = "PrimaryKey"
If Not SgvTbl.EOF Then
    SgvTbl.MoveFirst
    Do Until SgvTbl.EOF Or TotalPositions >= MaxPositions
        PositionNames(TotalPositions) = SgvTbl("PositionName")
        PositionDescs(TotalPositions) = SgvTbl("Description")
        TotalPositions = TotalPositions + 1
        SgvTbl.MoveNext
    Loop
End If
Set SgvTbl = SgvDb.OpenRecordset("tblCandidates")
If Not SgvTbl.EOF Then
    SgvTbl.MoveFirst
    Do Until SgvTbl.EOF Or TotalCandidates >= MaxCandidates
        CandidateSids(TotalCandidates) = SgvTbl("CSID")
        CandidateFnames(TotalCandidates) = SgvTbl("FirstName")
        CandidateLnames(TotalCandidates) = SgvTbl("LastName")
        CandidateMsgs(TotalCandidates) = SgvTbl("Message")
        Value = SgvTbl("Positions")
        For Count = 0 To TotalPositions - 1
            CandidatePositions(TotalCandidates, Count) = Value And 1
            Value = Value \ 2
        Next
    
        LoadDbPic CandidatePics(TotalCandidates)
        TotalCandidates = TotalCandidates + 1
        SgvTbl.MoveNext
    Loop
End If

SgvTbl.Close
SgvErr = False
Unload frmDbConnect

Exit Sub

DbError:
ShowDbError
End Sub


Public Sub StoreToDatabase()

Dim CurCandidate, Count, Value

'!!! idiotic VB won't let me show this form because there is
'    another modal form already shown. how stupid!
'frmDbConnect.Show
'frmDbConnect.lblProgress.Caption = "Writing..."
DoEvents

'save changes to candidates and their information
'On Error GoTo DbError
Set SgvTbl = SgvDb.OpenRecordset("tblCandidates", dbOpenTable)
SgvTbl.Index = "PrimaryKey"
For CurCandidate = 0 To TotalCandidates - 1
    If CandidateChanged(CurCandidate) Then
        SgvTbl.Seek "=", CandidateSids(CurCandidate)
        If SgvTbl.NoMatch Then
            SgvTbl.AddNew
        Else
            SgvTbl.Edit
        End If
        SgvTbl("CSID") = CandidateSids(CurCandidate)
        SgvTbl("FirstName") = CandidateFnames(CurCandidate)
        SgvTbl("LastName") = CandidateLnames(CurCandidate)
        SgvTbl("Message") = CandidateMsgs(CurCandidate)
        Value = 0
        For Count = TotalPositions - 1 To 0 Step -1
            Value = Value * 2 Or (CandidatePositions(CurCandidate, Count) And 1)
        Next
        SgvTbl("Positions") = Value
        CandidateChanged(CurCandidate) = False
        StoreDbPic CandidatePics(CurCandidate), AppPath & Format(CandidateSids(CurCandidate), "000000000.bmp")
        SgvTbl.Update
    End If
Next
SgvTbl.Close
SgvErr = False
'Unload frmDbConnect

Exit Sub

DbError:
ShowDbError
End Sub


Public Sub StoreDbVotes(VSID, VPAC, Selections())
Dim Count, Value

On Error GoTo DbError
Set SgvTbl = SgvDb.OpenRecordset("SELECT * FROM tblVotes WHERE VSID=" & VSID & " AND VPAC=" & VPAC)
If SgvTbl.RecordCount > 0 Then
    'end if votes have already been cast before
    MsgBox "Your votes have already been cast. Sorry, but you can't vote again or change your previous vote.", vbExclamation
    SgvErr = True
    SgvTbl.Close
    Exit Sub
End If

'cast new votes
Set SgvTbl = SgvDb.OpenRecordset("tblVotes")
For Count = 0 To TotalPositions - 1
    Value = Selections(Count)
    If Value >= 0 Then
        SgvTbl.AddNew
        SgvTbl("VSID") = VSID
        SgvTbl("VPAC") = VPAC
        SgvTbl("CSID") = CandidateSids(Value)
        SgvTbl("Position") = Count
        SgvTbl.Update
    End If
Next
SgvTbl.Close
SgvErr = False
Exit Sub

DbError:
ShowDbError
End Sub

#If TestingCode Then
Public Sub LoadTestData()

TotalPositions = 5
PositionNames(0) = "Senate"
PositionNames(1) = "Student Relations"
PositionNames(2) = "College Representatives"
PositionNames(3) = "Clubs & Organizations"
PositionNames(4) = "Finance"

TotalCandidates = 6
CandidateSids(0) = 636033929
CandidateSids(1) = 111111111
CandidateSids(2) = 222222222
CandidateSids(3) = 333333333
CandidateSids(4) = 444444444
CandidateSids(5) = 555555555
CandidateFnames(0) = "Jared"
CandidateLnames(0) = "Parks"
CandidateFnames(1) = "Dwayne"
CandidateLnames(1) = "Robinson"
CandidateFnames(2) = "Sarah"
CandidateLnames(2) = "Janecyk"
CandidateFnames(3) = "Scott"
CandidateLnames(3) = "Dove"
CandidateFnames(4) = "Russell"
CandidateLnames(4) = "Honbeck"
CandidateFnames(5) = "Daniel"
CandidateLnames(5) = "Walker"
CandidateMsgs(0) = "Asked me to write this program"
CandidateMsgs(1) = "Author of this program"
CandidateMsgs(2) = "Pretty senator that was impressed by my piano playing"
CandidateMsgs(3) = "Best friend"
CandidateMsgs(4) = "Closest thing to a brother"
CandidateMsgs(5) = "Friend since the age of six"
CandidatePositions(0, 0) = True
CandidatePositions(0, 1) = True
CandidatePositions(1, 1) = True
CandidatePositions(2, 1) = True
CandidatePositions(3, 1) = True
CandidatePositions(4, 1) = True
CandidatePositions(0, 2) = True
CandidatePositions(1, 2) = True
CandidatePositions(2, 2) = True
CandidatePositions(3, 2) = True
CandidatePositions(4, 2) = True
CandidatePositions(5, 2) = True
ChDir AppPath
Dim Count
For Count = 0 To TotalCandidates - 1
    Set CandidatePics(Count) = LoadPicture(Format(CandidateSids(Count), "000000000.bmp"))
Next

End Sub
#End If


Public Sub ShowDbError()
MsgBox "Database error:" & vbNewLine & Err.Description, vbCritical
SgvErr = True
Unload frmDbConnect
End Sub

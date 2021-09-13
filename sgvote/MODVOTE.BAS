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

Private Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long
Const OFNHideReadOnly = 4, OFNFileMustExist = 4096
Dim ofn As OPENFILENAME


Const DbFileName As String = "c:\temp\SgVote.mdb"
Public Const MaxCandidates = 50    'maximum number of candidates in all positions
Public Const MaxPosCandidates = 10 'maximum number of candidates in a single position
Public Const MaxPositions = 5      'total number of positions to apply for
Public TotalCandidates
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


Public Sub Main()

AppPath = App.Path
If Right(AppPath, 1) <> "\" Then AppPath = AppPath & "\"

PositionNames(0) = "Senate"
PositionNames(1) = "Student Relations"
PositionNames(2) = "College Representatives"
PositionNames(3) = "Clubs & Organizations"
PositionNames(4) = "Finance"

'initialize database object
frmDbConnect.Show
frmDbConnect.lblProgress.Caption = "Connecting..."
DoEvents

On Error GoTo DbError
Set SgvDb = OpenDatabase(DbFileName)
LoadFromDatabase
On Error GoTo 0
frmVote.Show vbModal
'frmEditCandidates.Show vbModal
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
            'FileName = AppPath & FileName
            FileName = "c:\temp\" & FileName
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

Public Function GetOpenFile(Filter As String, Title As String, hwnd As Long) As String
    Static Recurse As Boolean

    If Recurse Then Exit Function
    Recurse = True
    ofn.lStructSize = Len(ofn)
    ofn.hwndOwner = hwnd
    ofn.hInstance = App.hInstance
    ofn.lpstrFilter = Filter
    ofn.lpstrFile = Space$(254)
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
On Error GoTo DbError
Set SgvTbl = SgvDb.OpenRecordset("tblCandidates")
SgvTbl.MoveFirst
'TotalCandidates = 0
Do Until SgvTbl.EOF Or TotalCandidates >= MaxCandidates
    CandidateSids(TotalCandidates) = SgvTbl("SID")
    CandidateFnames(TotalCandidates) = SgvTbl("FirstName")
    CandidateLnames(TotalCandidates) = SgvTbl("LastName")
    CandidateMsgs(TotalCandidates) = SgvTbl("Message")
    Value = SgvTbl("Positions")
    For Count = 0 To MaxPositions - 1
        CandidatePositions(TotalCandidates, Count) = Value And 1
        Value = Value \ 2
    Next

    LoadDbPic CandidatePics(TotalCandidates)
    TotalCandidates = TotalCandidates + 1
    SgvTbl.MoveNext
Loop
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
Set SgvTbl = SgvDb.OpenRecordset("tblCandidates")
SgvTbl.Index = "SID"
For CurCandidate = 0 To TotalCandidates - 1
    If CandidateChanged(CurCandidate) Then
        SgvTbl.Seek "=", CandidateSids(CurCandidate)
        If SgvTbl.NoMatch Then
            SgvTbl.AddNew
        Else
            SgvTbl.Edit
        End If
        SgvTbl("SID") = CandidateSids(CurCandidate)
        SgvTbl("FirstName") = CandidateFnames(CurCandidate)
        SgvTbl("LastName") = CandidateLnames(CurCandidate)
        SgvTbl("Message") = CandidateMsgs(CurCandidate)
        Value = 0
        For Count = 0 To MaxPositions - 1
            Value = Value * 2 Or (CandidatePositions(CurCandidate, Count) And 1)
        Next
        SgvTbl("Positions") = Value
        CandidateChanged(CurCandidate) = False
        StoreDbPic CandidatePics(CurCandidate), "c:\temp\" & Format(CandidateSids(CurCandidate), "000000000") & ".bmp"
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


public sub SubmitVotes (VSID, Selections())
dim Count, Candidate

'On Error GoTo DbError
Set SgvTbl = SgvDb.OpenRecordset("tblVotes")
SgvTbl.Index = "VSID,Position"
for Count = 0 to MaxPositions-1
    Candidate=Selections(Count)
    SgvTbl.Seek "=", VSID, CandidateSids(Candidate)
    if Candidate < 0 then
        If not SgvTbl.NoMatch Then sgvtbl.delete
    else
        If SgvTbl.NoMatch Then
            SgvTbl.AddNew
        Else        
            SgvTbl.Edit
        end if
        SgvTbl("VSID") = VSID
        SgvTbl("Position") = Count
        SgvTbl("SID") = CandidateSids(Candidate)
    End If
next

DbError:
ShowDbError
end sub


Public Sub ShowDbError()
MsgBox "Database error:" & vbNewLine & Err.Description, vbCritical
SgvErr = True
Unload frmDbConnect
End Sub

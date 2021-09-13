VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   4980
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6975
   LinkTopic       =   "Form1"
   ScaleHeight     =   4980
   ScaleWidth      =   6975
   StartUpPosition =   3  'Windows Default
   Begin MSComctlLib.ImageList ImageList1 
      Left            =   4800
      Top             =   240
      _ExtentX        =   1005
      _ExtentY        =   1005
      BackColor       =   -2147483643
      ImageWidth      =   16
      ImageHeight     =   16
      _Version        =   393216
      BeginProperty Images {2C247F25-8591-11D1-B16A-00C0F0283628} 
         NumListImages   =   8
         BeginProperty ListImage1 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":0000
            Key             =   ""
         EndProperty
         BeginProperty ListImage2 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":0120
            Key             =   ""
         EndProperty
         BeginProperty ListImage3 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":0240
            Key             =   ""
         EndProperty
         BeginProperty ListImage4 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":0360
            Key             =   ""
         EndProperty
         BeginProperty ListImage5 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":0480
            Key             =   ""
         EndProperty
         BeginProperty ListImage6 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":05A0
            Key             =   ""
         EndProperty
         BeginProperty ListImage7 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":06C0
            Key             =   ""
         EndProperty
         BeginProperty ListImage8 {2C247F27-8591-11D1-B16A-00C0F0283628} 
            Picture         =   "treeview.frx":07E0
            Key             =   ""
         EndProperty
      EndProperty
   End
   Begin MSComctlLib.TreeView TreeView1 
      Height          =   4815
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   5415
      _ExtentX        =   9551
      _ExtentY        =   8493
      _Version        =   393217
      HideSelection   =   0   'False
      Indentation     =   0
      Style           =   5
      ImageList       =   "ImageList1"
      Appearance      =   1
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub Form_Load()
    Dim nodX As Node, Index As Integer, Text As String

    'Text = "Opcodes": GoSub AddBranch
    Set nodX = TreeView1.Nodes.Add(, tvwChild, , "Dumb Root!!", 6)
    Index = nodX.Index
    Text = "Opcodes": GoSub AddBranch
    Text = "Type": GoSub AddBranch
    Text = "Mathematical": GoSub AddElement
    Text = "Path control": GoSub AddElement
    Text = "Data movement": GoSub AddElement
    Text = "Stack operation": GoSub AddElement
    GoSub CloseBranch
    Text = "Value": GoSub AddBranch
    Text = "00-0F": GoSub AddElement
    Text = "10-1F": GoSub AddElement
    Text = "20-2F": GoSub AddElement
    Text = "30-FF": GoSub AddElement
    GoSub CloseBranch
    GoSub CloseBranch
    Text = "SPC registers": GoSub AddBranch
    Text = "Timer": GoSub AddElement
    Text = "Control": GoSub AddElement
    Text = "Data port": GoSub AddElement
    Text = "Counter": GoSub AddElement
    GoSub CloseBranch
    Text = "DSP registers": GoSub AddBranch
    Text = "Type": GoSub AddBranch
    Text = "Pitch": GoSub AddElement
    Text = "Volume": GoSub AddElement
    Text = "Gain": GoSub AddElement
    Text = "Source": GoSub AddElement
    GoSub CloseBranch
    Text = "Value": GoSub AddBranch
    Text = "00-0F": GoSub AddElement
    Text = "10-1F": GoSub AddElement
    Text = "20-2F": GoSub AddElement
    Text = "30-7F": GoSub AddElement
    GoSub CloseBranch
    TreeView1.Nodes(2).Selected = True
Exit Sub
    
AddBranch:
    Set nodX = TreeView1.Nodes.Add(Index, tvwChild, , Text, 7)
    Index = nodX.Index
Return

AddElement:
    Set nodX = TreeView1.Nodes.Add(Index, tvwChild, , Text, 4)
Return

CloseBranch:
    Index = TreeView1.Nodes(Index).Parent.Index
    nodX.EnsureVisible ' Show all nodes.
Return

End Sub

VERSION 5.00
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCT2.OCX"
Begin VB.Form frmGroup 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Group"
   ClientHeight    =   2790
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   5205
   Icon            =   "frmGroup.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   2790
   ScaleWidth      =   5205
   StartUpPosition =   1  'CenterOwner
   Begin VB.Frame Frame2 
      Caption         =   "Key Word(s) 1:"
      Height          =   615
      Left            =   0
      TabIndex        =   16
      Top             =   720
      Width           =   3135
      Begin VB.TextBox txtKey1 
         Height          =   285
         Left            =   120
         TabIndex        =   17
         Top             =   240
         Width           =   2895
      End
   End
   Begin VB.Frame Frame3 
      Caption         =   "Key Word(s) 2:"
      Height          =   615
      Left            =   0
      TabIndex        =   14
      Top             =   1440
      Width           =   3135
      Begin VB.TextBox txtKey2 
         Height          =   285
         Left            =   120
         TabIndex        =   15
         Top             =   240
         Width           =   2895
      End
   End
   Begin VB.Frame Frame4 
      Caption         =   "Key Word(s) 3:"
      Height          =   615
      Left            =   0
      TabIndex        =   12
      Top             =   2160
      Width           =   3135
      Begin VB.TextBox txtKey3 
         Height          =   285
         Left            =   120
         TabIndex        =   13
         Top             =   240
         Width           =   2895
      End
   End
   Begin VB.Frame Frame5 
      Caption         =   "Min Size (In Megs):"
      Height          =   735
      Left            =   3240
      TabIndex        =   9
      Top             =   720
      Width           =   1935
      Begin VB.TextBox txtMinSize 
         Enabled         =   0   'False
         Height          =   405
         Left            =   120
         TabIndex        =   10
         Text            =   "0"
         Top             =   240
         Width           =   1335
      End
      Begin MSComCtl2.UpDown UpDown1 
         Height          =   375
         Left            =   1560
         TabIndex        =   11
         Top             =   240
         Width           =   240
         _ExtentX        =   423
         _ExtentY        =   661
         _Version        =   393216
         Enabled         =   0   'False
      End
   End
   Begin VB.Frame Frame6 
      Caption         =   "Max Size (In Megs):"
      Height          =   735
      Left            =   3240
      TabIndex        =   6
      Top             =   1560
      Width           =   1935
      Begin VB.TextBox txtMaxSize 
         Enabled         =   0   'False
         Height          =   375
         Left            =   120
         TabIndex        =   7
         Text            =   "0"
         Top             =   240
         Width           =   1335
      End
      Begin MSComCtl2.UpDown UpDown2 
         Height          =   375
         Left            =   1560
         TabIndex        =   8
         Top             =   240
         Width           =   240
         _ExtentX        =   423
         _ExtentY        =   661
         _Version        =   393216
         Enabled         =   0   'False
      End
   End
   Begin VB.CommandButton cmdSave 
      Caption         =   "Save"
      Default         =   -1  'True
      Height          =   375
      Left            =   4320
      TabIndex        =   5
      Top             =   2400
      Width           =   855
   End
   Begin VB.CommandButton cmdCancel 
      Caption         =   "Cancel"
      Height          =   375
      Left            =   3240
      TabIndex        =   4
      Top             =   2400
      Width           =   855
   End
   Begin VB.CheckBox chkTV 
      Caption         =   "TV Series"
      Height          =   255
      Left            =   3840
      TabIndex        =   3
      Top             =   120
      Width           =   1095
   End
   Begin VB.CheckBox chkMulti 
      Caption         =   "Multi-Ep Files"
      Height          =   255
      Left            =   3840
      TabIndex        =   2
      Top             =   360
      Width           =   1335
   End
   Begin VB.Frame Frame1 
      Caption         =   "Title:"
      Height          =   615
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   3735
      Begin VB.TextBox txtTitle 
         Height          =   285
         Left            =   120
         TabIndex        =   1
         Top             =   240
         Width           =   3495
      End
   End
End
Attribute VB_Name = "frmGroup"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

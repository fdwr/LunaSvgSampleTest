VERSION 5.00
Begin VB.Form frmGforceTest 
   Caption         =   "G-force Test"
   ClientHeight    =   4440
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9945
   Icon            =   "GforceTest.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   296
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   663
   StartUpPosition =   3  'Windows Default
   Begin prjGforceTest.GforceImage gfiSrc 
      Height          =   3600
      Left            =   120
      Top             =   120
      Width           =   4800
      _ExtentX        =   8467
      _ExtentY        =   6350
   End
   Begin VB.CommandButton cmdClose 
      Cancel          =   -1  'True
      Caption         =   "Close"
      Height          =   480
      Left            =   8640
      TabIndex        =   4
      Top             =   3840
      Width           =   1200
   End
   Begin VB.CommandButton Command3 
      Caption         =   "Reset"
      Height          =   480
      Left            =   4080
      TabIndex        =   3
      Top             =   3840
      Width           =   1200
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Reset"
      Height          =   480
      Left            =   2760
      TabIndex        =   2
      Top             =   3840
      Width           =   1200
   End
   Begin VB.CommandButton cmdNext 
      Caption         =   "Next"
      Height          =   480
      Left            =   1440
      TabIndex        =   1
      Top             =   3840
      Width           =   1200
   End
   Begin VB.CommandButton cmdReset 
      Caption         =   "Reset"
      Height          =   480
      Left            =   120
      TabIndex        =   0
      Top             =   3840
      Width           =   1200
   End
   Begin prjGforceTest.GforceImage GfiDst 
      Height          =   3600
      Left            =   5040
      Top             =   120
      Width           =   4800
      _ExtentX        =   8467
      _ExtentY        =   6350
   End
End
Attribute VB_Name = "frmGforceTest"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim BmpSrcHnd As Long
Dim BmpDstHnd As Long

Sub Terminate()
    DeleteObject
End Sub


Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub Form_Load()
    BmpSrcHnd = CreateDIBitmap(GetDC(frmGforceTest.hwnd), BmpHeader, CBM_INIT, BmpSrc(0), BmpHeader, DIB_RGB_COLORS)
    BmpDstHnd = CreateDIBitmap(GetDC(frmGforceTest.hwnd), BmpHeader, CBM_INIT, BmpSrc(0), BmpHeader, DIB_RGB_COLORS)
    'imgSrc.Picture = BmpSrcHnd as IPictureDisp
    'imgDst.Picture = BmpDstHnd
End Sub

'api SetDIBitsToDevice, [hDC], 0, 0, Bmp_Width, Bmp_Height, 0, 0, 0, Bmp_Height, Screen.Buffer, Display.BmpHeader, DIB_PAL_COLORS

Private Sub Image2_Click()

End Sub

Private Sub Form_Unload(Cancel As Integer)
    DeleteObject BmpSrcHnd
    DeleteObject BmpDstHnd
End Sub


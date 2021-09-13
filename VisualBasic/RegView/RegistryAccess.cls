VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "RegistryAccess"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Option Base 0
Option Compare Binary
' Module to aid VB in general registry access
' all routines return Boolean True/False for success
' requested values are in updated parameters

' Win32 API structures for Registry calls
Private Type FILETIME
  dwLowDateTime As Long
  dwHighDateTime As Long
End Type
Private Type SECURITY_ATTRIBUTES
  nLength As Long
  lpSecurityDescriptor As Long
  bInheritHandle As Long
End Type
Private Type SYSTEMTIME
  wYear As Integer
  wMonth As Integer
  wDayOfWeek As Integer
  wDay As Integer
  wHour As Integer
  wMinute As Integer
  wSecond As Integer
  wMilliseconds As Integer
End Type
' API calls needed for registry access
Private Declare Function RegOpenKey Lib "advapi32.dll" _
  Alias "RegOpenKeyA" (ByVal hKey As Long, ByVal lpSubKey As String, _
  phkResult As Long) As Long
Private Declare Function RegOpenKeyEx Lib "advapi32.dll" _
  Alias "RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, _
  ByVal ulOptions As Long, ByVal samDesired As Long, _
  phkResult As Long) As Long
Private Declare Function RegCreateKey Lib "advapi32.dll" _
  Alias "RegCreateKeyA" (ByVal hKey As Long, ByVal lpSubKey As String, _
  phkResult As Long) As Long
Private Declare Function RegCreateKeyEx Lib "advapi32.dll" _
  Alias "RegCreateKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, _
  ByVal Reserved As Long, ByVal lpClass As String, ByVal dwOptions As Long, _
  ByVal samDesired As Long, lpSecurityAttributes As Any, _
  phkResult As Long, lpdwDisposition As Long) As Long
Private Declare Function RegDeleteKey Lib "advapi32.dll" _
  Alias "RegDeleteKeyA" (ByVal hKey As Long, _
  ByVal lpSubKey As String) As Long
Private Declare Function RegEnumKey Lib "advapi32.dll" _
  Alias "RegEnumKeyA" (ByVal hKey As Long, ByVal dwIndex As Long, _
  ByVal lpName As String, ByVal cbName As Long) As Long
Private Declare Function RegEnumKeyEx Lib "advapi32.dll" _
  Alias "RegEnumKeyExA" (ByVal hKey As Long, ByVal dwIndex As Long, _
  ByVal lpName As String, lpcbName As Long, ByVal lpReserved As Long, _
  ByVal lpClass As String, lpcbClass As Long, _
  lpftLastWriteTime As FILETIME) As Long
Private Declare Function RegEnumValue Lib "advapi32.dll" _
  Alias "RegEnumValueA" (ByVal hKey As Long, ByVal dwIndex As Long, _
  ByVal lpValueName As String, lpcbValueName As Long, _
  ByVal lpReserved As Long, lpType As Long, lpData As Any, _
  lpcbData As Long) As Long
Private Declare Function RegQueryValue Lib "advapi32.dll" _
  Alias "RegQueryValueA" (ByVal hKey As Long, ByVal lpSubKey As String, _
  ByVal lpValue As String, lpcbValue As Long) As Long
Private Declare Function RegQueryValueEx Lib "advapi32.dll" _
  Alias "RegQueryValueExA" (ByVal hKey As Long, _
  ByVal lpValueName As String, ByVal lpReserved As Long, _
  lpType As Long, lpData As Any, lpcbData As Long) As Long
Private Declare Function RegDeleteValue Lib "advapi32.dll" _
  Alias "RegDeleteValueA" (ByVal hKey As Long, _
  ByVal lpValueName As String) As Long
Private Declare Function RegSetValue Lib "advapi32.dll" _
  Alias "RegSetValueA" (ByVal hKey As Long, ByVal lpSubKey As String, _
  ByVal dwType As Long, ByVal lpData As String, _
  ByVal cbData As Long) As Long
Private Declare Function RegSetValueEx Lib "advapi32.dll" _
  Alias "RegSetValueExA" (ByVal hKey As Long, _
  ByVal lpValueName As String, ByVal Reserved As Long, _
  ByVal dwType As Long, lpData As Any, ByVal cbData As Long) As Long
Private Declare Function RegCloseKey Lib "advapi32.dll" _
  (ByVal hKey As Long) As Long
Private Declare Function RegConnectRegistry Lib "advapi32.dll" _
  Alias "RegConnectRegistryA" (ByVal lpMachineName As String, _
  ByVal hKey As Long, phkResult As Long) As Long
Private Declare Function RegQueryInfoKey Lib "advapi32.dll" _
  Alias "RegQueryInfoKeyA" (ByVal hKey As Long, ByVal lpClass As String, _
  lpcbClass As Long, lpReserved As Long, lpcSubKeys As Long, _
  lpcbMaxSubKeyLen As Long, lpcbMaxClassLen As Long, lpcValues As Long, _
  lpcbMaxValueNameLen As Long, lpcbMaxValueLen As Long, lpcbSecurityDescriptor As Long, _
  lpftLastWriteTime As FILETIME) As Long
' miscellaneous support API calls
Private Declare Function FileTimeToSystemTime Lib "Kernel32" _
  (lpFileTime As FILETIME, lpSystemTime As SYSTEMTIME) As Long
Private Declare Sub CopyMemory Lib "Kernel32" Alias "RtlMoveMemory" _
  (xdest As Any, xsource As Any, ByVal xsize As Long)

' The following constants can be used for the security
' parameters in the registry calls. Win95/98 ignores
' them but NT enforces them. This class uses only
' KEY_READ and KEY_ALL_ACCESS but the rest are here for future
' extensions
Private Const KEY_SET_VALUE = &H2
Private Const KEY_CREATE_SUB_KEY = &H4
Private Const SYNCHRONIZE = &H100000
Private Const STANDARD_RIGHTS_WRITE = &H20000
Private Const STANDARD_RIGHTS_READ = &H20000
Private Const KEY_EVENT = &H1
Private Const STANDARD_RIGHTS_ALL = &H1F0000
Private Const KEY_QUERY_VALUE = &H1
Private Const KEY_NOTIFY = &H10
Private Const KEY_ENUMERATE_SUB_KEYS = &H8
Private Const KEY_CREATE_LINK = &H20
Private Const KEY_ALL_ACCESS = ((STANDARD_RIGHTS_ALL Or KEY_QUERY_VALUE Or _
  KEY_SET_VALUE Or KEY_CREATE_SUB_KEY Or KEY_ENUMERATE_SUB_KEYS Or _
  KEY_NOTIFY Or KEY_CREATE_LINK) And (Not SYNCHRONIZE))
Private Const KEY_READ = ((STANDARD_RIGHTS_READ Or KEY_QUERY_VALUE Or _
  KEY_ENUMERATE_SUB_KEYS Or KEY_NOTIFY) And (Not SYNCHRONIZE))
Private Const KEY_WRITE = ((STANDARD_RIGHTS_WRITE Or KEY_SET_VALUE Or _
  KEY_CREATE_SUB_KEY) And (Not SYNCHRONIZE))
Private Const KEY_EXECUTE = (KEY_READ)

' And we need to know if calls succeed
Private Const ERROR_SUCCESS = 0

' expose registry constants to the caller
' we use nonstandard names to avoid conflicts
Public Enum enmHives
  rgClassesRoot = &H80000000
  rgCurrentConfig = &H80000005
  rgCurrentUser = &H80000001
  rgDynamicData = &H80000006
  rgLocalMachine = &H80000002
  rgPerformanceData = &H80000004
  rgUsers = &H80000003
End Enum

Public Enum enmDataType
  rgUnknown = 0
  rgStringZ = 1
  rgExpandStringZ = 2
  rgBinary = 3
  rgDWord = 4
  rgDwordLittleEndian = 4
  rgDWordBigEndian = 5
  rgMultiStringZ = 7
End Enum

Public Enum enmErrors
  errDataType = vbObjectError + 512
End Enum

' keep track of the results of the last action
Private msLastErrorSource As String
Private mlLastErrorNumber As Long

Public Property Get LastErrorNumber() As Long
' caller can inquire to get error specifics
LastErrorNumber = mlLastErrorNumber
End Property

Public Property Get LastErrorSource() As String
' caller can get name of last routine attempted
LastErrorSource = msLastErrorSource
End Property

Private Sub SaveErrorInfo(ByVal ErrorSource As String, _
  ByVal ErrorNumber As Long)
' save routine name and result code
msLastErrorSource = ErrorSource
mlLastErrorNumber = ErrorNumber
End Sub

Public Function OpenRemote(ByVal RegHive As enmHives, _
  ByVal MachineName As String, ByRef TheKey As Long) As Boolean
Dim hKey As Long
' This routine allows the caller to open the registry on
' a remote system (access permitting)
Call SaveErrorInfo("OpenRemote", _
  RegConnectRegistry(MachineName, RegHive, TheKey))
If mlLastErrorNumber = ERROR_SUCCESS Then
  OpenRemote = True
Else
  TheKey = 0
End If
End Function

Public Function OpenKey(ByVal RegHive As enmHives, _
  ByVal KeyPath As String, ByVal ReadOnly As Boolean, _
  ByRef TheKey As Long) As Boolean
' gain access to registry key
Dim lAccess As Long
If ReadOnly Then
  lAccess = KEY_READ
Else
  lAccess = KEY_ALL_ACCESS ' we need both read & write
End If
Call SaveErrorInfo("OpenKey", _
  RegOpenKeyEx(RegHive, KeyPath, 0, lAccess, TheKey))
If mlLastErrorNumber = ERROR_SUCCESS Then
  OpenKey = True
Else
  TheKey = 0
End If
End Function

Public Function CloseKey(ByVal RegKey As Long) As Boolean
Dim x As Long
' release hold on registry key
Call SaveErrorInfo("CloseKey", RegCloseKey(RegKey))
If mlLastErrorNumber = ERROR_SUCCESS Then CloseKey = True
End Function

Public Function GetKeyValue(ByVal RegKey As Long, _
  ByVal KeyPath As String, ByRef TheValue As String) As Boolean
Dim sTemp As String
Dim lSize As Long
' get the value assciated with a key in the registry
' see GetNamedValue for other values
sTemp = Space$(256) ' guess at buffer size
lSize = Len(sTemp) - 1
Do
  If Len(KeyPath) > 0 Then
    Call SaveErrorInfo("GetKeyValue", _
      RegQueryValue(RegKey, KeyPath, sTemp, lSize))
  Else
    Call SaveErrorInfo("GetKeyValue", _
      RegQueryValue(RegKey, vbNullString, sTemp, lSize))
  End If
  If mlLastErrorNumber = ERROR_SUCCESS Then Exit Do
  If lSize >= Len(sTemp) Then
    ' buffer too small
    sTemp = Space$(lSize + 1)
  Else
    ' unknown error
    GetKeyValue = False
    TheValue = ""
    Exit Function
  End If
Loop
If lSize > 0 Then
  TheValue = Left$(sTemp, lSize)
  If Right$(TheValue, 1) = vbNullChar Then TheValue = Left$(sTemp, lSize - 1)
Else
  TheValue = ""
End If
GetKeyValue = True
End Function

Public Function SetKeyValue(ByVal RegKey As Long, _
  ByVal KeyPath As String, ByVal TheValue As String) As Boolean
' Update the value associated with a key
' see SetNamedValue for other values
If Len(KeyPath) > 0 Then
  Call SaveErrorInfo("SetKeyValue", _
      RegSetValue(RegKey, KeyPath, rgStringZ, _
                  TheValue, Len(TheValue)))
Else
  Call SaveErrorInfo("SetKeyValue", _
      RegSetValue(RegKey, vbNullString, rgStringZ, _
                  TheValue, Len(TheValue)))
End If
If mlLastErrorNumber = ERROR_SUCCESS Then SetKeyValue = True
End Function

Public Function CreateKey(ByVal RegHive As enmHives, _
  ByVal KeyPath As String, ByRef TheKey As Long) As Boolean
' gain access to registry key - this will open an
' existing key or create and open a new key
Call SaveErrorInfo("CreateKey", _
  RegCreateKey(RegHive, KeyPath, TheKey))
If mlLastErrorNumber = ERROR_SUCCESS Then
  CreateKey = True
Else
  TheKey = 0
End If
End Function

Public Function DeleteKey(ByVal RegKey As Long, _
  ByVal KeyPath As String) As Boolean
' remove key from registry
Call SaveErrorInfo("DeleteKey", _
  RegDeleteKey(RegKey, KeyPath))
If mlLastErrorNumber = ERROR_SUCCESS Then DeleteKey = True
End Function

Public Function GetHiveName(ByVal RegHive As enmHives, _
  ByRef TheName As String) As Boolean
' Routine to translate constant to human-readable name
GetHiveName = True
Select Case RegHive
  Case rgLocalMachine: TheName = "HKEY_LOCAL_MACHINE"
  Case rgCurrentUser: TheName = "HKEY_CURRENT_USER"
  Case rgClassesRoot: TheName = "HKEY_CLASSES_ROOT"
  Case rgCurrentConfig: TheName = "HKEY_CURRENT_CONFIG"
  Case rgDynamicData: TheName = "HKEY_DYNAMIC_DATA"
  Case rgPerformanceData: TheName = "HKEY_PERFORMANCE_DATA"
  Case rgUsers: TheName = "HKEY_USERS"
  Case Else: TheName = "": GetHiveName = False
End Select
End Function

Public Function GetHiveKey(ByVal HiveName As String, _
  ByRef TheHive As enmHives) As Boolean
Dim sTemp As String
Dim x As Long
' Routine to translate human-readable name to numeric value
sTemp = UCase$(HiveName)
x = InStr(1, sTemp, "\")
If x > 0 Then sTemp = Left$(sTemp, x - 1)
GetHiveKey = True
Select Case sTemp
  Case "HKEY_LOCAL_MACHINE": TheHive = rgLocalMachine
  Case "HKEY_CURRENT_USER": TheHive = rgCurrentUser
  Case "HKEY_CLASSES_ROOT": TheHive = rgClassesRoot
  Case "HKEY_CURRENT_CONFIG": TheHive = rgCurrentConfig
  Case "HKEY_DYNAMIC_DATA": TheHive = rgDynamicData
  Case "HKEY_PERFORMANCE_DATA": TheHive = rgPerformanceData
  Case "HKEY_USERS": TheHive = rgUsers
  Case Else: TheHive = 0: GetHiveKey = 0
End Select
End Function

Public Function DeNull(ByVal StringValue As String) As String
Dim x As Long
' this truncates a string at the first Null character
x = InStr(StringValue, vbNullChar)
If x > 0 Then
  DeNull = Left$(StringValue, x - 1)
Else
  DeNull = StringValue
End If
End Function

Public Function NextString(ByRef StringValue As String) As String
Dim x As Long
' routine to aid in parsing a MultStringZ value
' multstrings look like:
' string1<null>string2<null>string3<null><null>
x = InStr(StringValue, vbNullChar)
If x > 0 Then
  NextString = Left$(StringValue, x - 1)
  StringValue = Mid$(StringValue, x + 1)
Else
  NextString = StringValue
  StringValue = ""
End If
End Function

Public Function GetKeyInfo(ByVal RegKey As Long, _
  ByRef ClassName As String, ByRef SubKeys As Long, _
  ByRef MaxSubKeyLength As Long, ByRef MaxClassLength As Long, _
  ByRef DataValues As Long, ByRef MaxDataValueLength As Long, _
  ByRef MaxDataNameLength As Long, ByRef SecurityLength As Long, _
  ByRef LastModified As Date) As Boolean
Dim sTemp As String
Dim lSize As Long
Dim uTime As FILETIME
Dim uSysTime As SYSTEMTIME
' This routine is provided to allow the caller to query
' a key for information about the number and size of
' all subkeys and associated values
sTemp = Space$(256) ' guess at buffer size
lSize = Len(sTemp) - 1
Do
  Call SaveErrorInfo("GetKeyInfo", _
    RegQueryInfoKey(RegKey, sTemp, lSize, ByVal 0&, _
    SubKeys, MaxSubKeyLength, MaxClassLength, _
    DataValues, MaxDataValueLength, MaxDataNameLength, _
    SecurityLength, uTime))
  If mlLastErrorNumber = ERROR_SUCCESS Then Exit Do
  If lSize >= Len(sTemp) Then
    ' buffer too small
    sTemp = Space$(lSize + 1)
  Else
    ' unknown error
    GetKeyInfo = False
    SubKeys = 0
    MaxSubKeyLength = 0
    MaxClassLength = 0
    DataValues = 0
    MaxDataValueLength = 0
    MaxDataNameLength = 0
    SecurityLength = 0
    LastModified = CDate("01-Jan-1980")
  End If
Loop
If lSize > 0 Then
  ClassName = Left$(sTemp, lSize)
Else
  ClassName = ""
End If
' convert time structure (returned in NT only)
Call FileTimeToSystemTime(uTime, uSysTime)
With uSysTime
  LastModified = DateSerial(.wYear, .wMonth, .wDay) + _
    TimeSerial(.wHour, .wMinute, .wSecond)
End With
GetKeyInfo = True
End Function

Public Function SetNamedValue(ByVal RegKey As Long, _
  ByVal ValueName As String, _
  ByVal TheValue As Variant) As Boolean
Dim lType As Long
Dim bytArray() As Byte
' This sets the value for a named value associated
' with a registry key. The datatype of the parameter
' passed in determines the type used:
' string=string, string with NULL=multstring,
' byte or byte array=binary, boolean or integer or long=dword
lType = VarType(TheValue)
Select Case VarType(TheValue)
  Case vbInteger, vbLong, vbBoolean:
    SetNamedValue = SetNamedValueLong(RegKey, ValueName, CLng(TheValue))
  Case vbString:
    SetNamedValue = SetNamedValueString(RegKey, ValueName, CStr(TheValue))
  Case vbByte:
    ReDim bytArray(1 To 1)
    bytArray(1) = TheValue
    SetNamedValue = SetNamedValueBinary(RegKey, ValueName, bytArray)
    Erase bytArray
  Case Else:
    If (lType And vbArray And vbByte) = (vbArray And vbByte) Then
      bytArray = TheValue
      SetNamedValue = SetNamedValueBinary(RegKey, ValueName, bytArray)
      Erase bytArray
    Else
      SetNamedValue = False
      Call SaveErrorInfo("SetNamedValue", errDataType)
    End If
End Select
End Function

Private Function SetNamedValueLong(ByVal RegKey As Long, _
  ByVal ValueName As String, ByVal TheValue As Long) As Boolean
' This is called by SetNamedValue to handle the DWORD case
Call SaveErrorInfo("SetNamedValue(Long)", _
  RegSetValueEx(RegKey, ValueName, 0, rgDWord, TheValue, 4))
If mlLastErrorNumber = ERROR_SUCCESS Then SetNamedValueLong = True
End Function

Private Function SetNamedValueBinary(ByVal RegKey As Long, _
  ByVal ValueName As String, TheValue() As Byte) As Boolean
' Called by SetNamedValue for binary data
Call SaveErrorInfo("SetNamedValue(Binary)", _
  RegSetValueEx(RegKey, ValueName, 0, rgBinary, _
    TheValue(LBound(TheValue)), _
    UBound(TheValue) - LBound(TheValue) + 1))
If mlLastErrorNumber = ERROR_SUCCESS Then SetNamedValueBinary = True
End Function

Private Function SetNamedValueString(ByVal RegKey As Long, _
  ByVal ValueName As String, ByVal TheValue As String) As Boolean
Dim lType As String
Dim x As Long
' called by SetNamedValue for strings
If InStr(1, TheValue, vbNullChar) > 0 Then
  lType = rgMultiStringZ
Else
  lType = rgStringZ
End If
Call SaveErrorInfo("SetNamedValue(String)", _
  RegSetValueEx(RegKey, ValueName, 0, lType, ByVal TheValue, Len(TheValue)))
If mlLastErrorNumber = ERROR_SUCCESS Then SetNamedValueString = True
End Function

Public Function GetNamedValue(ByVal RegKey As Long, _
  ByVal ValueName As String, ByRef ValueType As enmDataType, _
  ByRef TheValue As Variant) As Boolean
Dim lSize As Long
Dim bytTemp() As Byte
' Routine to return a the value for a named value associated
' with a registry key. The VB data type returned depends
' on the type in the registry
' string or multstring=string, dword=long,
' byte array=any other type, empty=unreadable
ReDim bytTemp(1 To 256) As Byte ' guess at buffer size
lSize = UBound(bytTemp)
Do
  Call SaveErrorInfo("GetNamedValue", _
    RegQueryValueEx(RegKey, ValueName, 0, ValueType, _
      bytTemp(1), lSize))
  If mlLastErrorNumber = ERROR_SUCCESS Then Exit Do
  If lSize > UBound(bytTemp) Then
    ' buffer too small
    Erase bytTemp
    ReDim bytTemp(1 To lSize)
  Else
    Erase bytTemp
    TheValue = Empty
    ValueType = rgUnknown
    Exit Function
  End If
Loop
Call ParseData(ValueType, lSize, bytTemp, TheValue)
Erase bytTemp
GetNamedValue = True
End Function

Private Sub ParseData(ByVal ValueType As Long, _
  ByVal DataSize As Long, ByRef DataBytes() As Byte, _
  ByRef TheValue As Variant)
Dim x As Long
' routine to look at regstry data and convert to
' best VB data type
Select Case ValueType
  Case rgDWord:
    Call CopyMemory(x, DataBytes(1), 4)
    TheValue = x
  Case rgStringZ, rgMultiStringZ:
    ReDim Preserve DataBytes(1 To DataSize)
    TheValue = StrConv(DataBytes, vbUnicode)
    If ValueType = rgStringZ Then
      If Len(TheValue) > 0 Then
        If Right$(TheValue, 1) = vbNullChar Then
          TheValue = Left$(TheValue, Len(TheValue) - 1)
        End If
      End If
    Else
      If Len(TheValue) > 0 Then
        If Right$(TheValue, 1) <> vbNullChar Then
          TheValue = TheValue & vbNullChar
        End If
      Else
        TheValue = vbNullChar
      End If
    End If
  Case Else:
    ReDim Preserve DataBytes(1 To DataSize)
    TheValue = DataBytes
End Select
End Sub

Public Function DeleteNamedValue(ByVal RegKey As Long, _
  ByVal ValueName As String) As Boolean
' removes a named value from the registry
Call SaveErrorInfo("DeleteValue", _
  RegDeleteValue(RegKey, ValueName))
If mlLastErrorNumber = ERROR_SUCCESS Then DeleteNamedValue = True
End Function

Public Function GetKeybyNumber(ByVal RegKey As Long, _
  ByVal KeyNumber As Long, ByRef KeyName As String) As Boolean
Dim sKey As String
Dim sClass As String
Dim lKeySize As Long
Dim lClassSize As Long
Dim uTime As FILETIME
' routine to allow the user to find all subkeys under
' a given key by querying for subkey 0, 1, 2, etc
sKey = Space$(256) ' guess at buffer sizes
sClass = Space$(256)
lKeySize = Len(sKey)
lClassSize = Len(sClass)
Do
  Call SaveErrorInfo("GetKeyByNumber", _
    RegEnumKeyEx(RegKey, KeyNumber, sKey, lKeySize, _
      0, sClass, lClassSize, uTime))
  If mlLastErrorNumber = ERROR_SUCCESS Then Exit Do
  If lKeySize > Len(sKey) Or lClassSize > Len(sClass) Then
    ' buffer too small
    sKey = Space$(lKeySize + 1)
    sClass = Space$(lClassSize + 1)
  Else
    GetKeybyNumber = False
    KeyName = ""
    Exit Function
  End If
Loop
If lKeySize > 0 Then
  KeyName = Left$(sKey, lKeySize)
Else
  KeyName = ""
End If
GetKeybyNumber = True
End Function

Public Function GetValueByNumber(ByVal RegKey As Long, _
  ByVal ValueNumber As Long, ByRef ValueName As String, _
  ByRef ValueType As enmDataType, ByRef TheValue As Variant) As Boolean
Dim sValue As String
Dim bytTemp() As Byte
Dim lValueSize As Long
Dim lDataSize As Long
' routine to allow the user to find all named values under
' a given key by querying for value 0, 1, 2, etc
sValue = Space$(256) ' guess at buffer sizes
ReDim bytTemp(1 To 256)
lValueSize = Len(sValue)
lDataSize = UBound(bytTemp)
Do
  Call SaveErrorInfo("GetSubKey", _
    RegEnumValue(RegKey, ValueNumber, sValue, lValueSize, _
      0, ValueType, bytTemp(1), lDataSize))
  If mlLastErrorNumber = ERROR_SUCCESS Then Exit Do
  If lValueSize > Len(sValue) Or lDataSize > UBound(bytTemp) Then
    ' buffer too small
    sValue = Space$(lValueSize + 1)
    Erase bytTemp
    ReDim bytTemp(1 To lDataSize + 1)
  Else
    GetValueByNumber = False
    ValueName = ""
    ValueType = rgUnknown
    TheValue = Empty
    Exit Function
  End If
Loop
If lValueSize > 0 Then
  ValueName = Left$(sValue, lValueSize)
Else
  ValueName = ""
End If
Call ParseData(ValueType, lDataSize, bytTemp, TheValue)
GetValueByNumber = True
End Function

Public Function CopyKey(ByVal SourceKey As Long, _
  ByVal DestinationKey As Long) As Boolean
Dim x As Long
Dim v As Variant
Dim sName As String
Dim sValue As String
Dim lType As Long
Dim hSubSource As Long
Dim hSubDest As Long
Dim bFailed As Boolean
' first, copy the sub keys
Do
  If Not GetKeybyNumber(SourceKey, x, sName) Then Exit Do
  If Not OpenKey(SourceKey, sName, True, hSubSource) Then
    bFailed = True
    Exit Do
  End If
  If Not CreateKey(DestinationKey, sName, hSubDest) Then
    bFailed = True
    Call CloseKey(hSubSource)
    Exit Do
  End If
  If Not CopyKey(hSubSource, hSubDest) Then bFailed = True
  Call CloseKey(hSubSource)
  Call CloseKey(hSubDest)
  x = x + 1
Loop Until bFailed = True
If bFailed Then Exit Function
' now the default value
If GetKeyValue(SourceKey, "", sValue) Then
  If Len(sValue) > 0 Then
    If Not SetKeyValue(DestinationKey, "", sValue) Then
      bFailed = True
    End If
  End If
End If
If bFailed Then Exit Function
' last, the named values
x = 0
Do
  If Not GetValueByNumber(SourceKey, x, sName, lType, v) Then Exit Do
  If Not SetNamedValue(DestinationKey, sName, v) Then bFailed = True
  x = x + 1
Loop Until bFailed = True
CopyKey = Not bFailed
End Function


' =====================================================================
'   Mavericks-RoboCopy.vbs  -  silent launcher (no console flash)
'   -----------------------------------------------------------------
'   WScript runs without ever allocating a console window, which is
'   the only reliable way to launch a hidden PowerShell process with
'   zero visible flash.
'
'   Detects PowerShell 7 by checking the standard install path AND
'   the WhereExists trick. The .ps1 itself is version-agnostic, so
'   either works.
' =====================================================================

Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path   = scriptDir & "\Mavericks-RoboCopy.ps1"

' Try common pwsh.exe locations first
psExe = ""
candidates = Array( _
    "C:\Program Files\PowerShell\7\pwsh.exe", _
    "C:\Program Files\PowerShell\7-preview\pwsh.exe", _
    "C:\Program Files (x86)\PowerShell\7\pwsh.exe" _
)
For Each c In candidates
    If fso.FileExists(c) Then
        psExe = c
        Exit For
    End If
Next

If psExe = "" Then
    psExe = "powershell.exe"   ' Fall back to Windows PowerShell 5.1
End If

cmd = """" & psExe & """ -NoProfile -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & ps1Path & """"

' Forward up to 2 dragged paths as -Source / -Destination
If WScript.Arguments.Count >= 1 Then cmd = cmd & " -Source """      & WScript.Arguments(0) & """"
If WScript.Arguments.Count >= 2 Then cmd = cmd & " -Destination """ & WScript.Arguments(1) & """"

' Run hidden (0), don't wait (False)
sh.Run cmd, 0, False

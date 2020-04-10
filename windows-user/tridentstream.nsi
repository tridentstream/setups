!include "MUI2.nsh"

!define APP_NAME "Tridentstream"
!define APP_URL "https://tridentstream.org/"

Unicode true

Name "Tridentstream"
OutFile "tridentstream-setup.exe"

InstallDir "$LOCALAPPDATA\Programs\Tridentstream"
InstallDirRegKey HKCU "Software\${APP_NAME}" "Install_Dir"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

Section "Install"
    AddSize 700000

    inetc::get /CAPTION "PostgreSQL Database" \
        "http://get.enterprisedb.com/postgresql/postgresql-12.2-2-windows-x64-binaries.zip" \
        "$TEMP/postgres.zip" /END
    
    nsisunz::UnzipToLog "$TEMP\postgres.zip" "$INSTDIR"
    Pop $0
    StrCmp $0 "success" ok
        DetailPrint "$0" ;print error message to log
    ok:

    inetc::get /CAPTION "Python 3.7" \
        "https://www.python.org/ftp/python/3.7.7/python-3.7.7-embed-amd64.zip" \
        "$TEMP\python-installer.zip" /END
    
    CreateDirectory "$INSTDIR\Python"
    nsisunz::UnzipToLog "$TEMP\python-installer.zip" "$INSTDIR\Python"
    Pop $0
    StrCmp $0 "success" ok2
        DetailPrint "$0" ;print error message to log
    ok2:

    inetc::get /CAPTION "Pip" \
        "https://bootstrap.pypa.io/get-pip.py" \
        "$TEMP\get-pip.py" /END
    
    ExecWait '"$INSTDIR\Python\python.exe" "$TEMP\get-pip.py"'
    Delete "$INSTDIR\Python\python37._pth"
    ExecWait '"$INSTDIR\Python\python.exe" -m pip install -U psycopg2-binary pyopenssl'
    ExecWait '"$INSTDIR\Python\python.exe" -m pip install tridentstream'

    SetOutPath "$INSTDIR"
    File "start.py"
    File "start.bat"
    File "icon.ico"
    CreateDirectory "$SMPROGRAMS\Tridentstream"
    CreateShortCut "$SMPROGRAMS\Tridentstream\Start Tridentstream.lnk" "$INSTDIR\start.bat" "" "$INSTDIR\icon.ico"
    WriteUninstaller "$INSTDIR\Uninstall Tridentstream.exe"
    CreateShortCut "$SMPROGRAMS\Tridentstream\Uninstall Tridenstream.lnk" "$INSTDIR\Uninstall Tridentstream.exe"
SectionEnd

Section "Uninstall"
    RMDir /r "$INSTDIR"
    RMDir /R "$SMPROGRAMS\Tridentstream"
SectionEnd
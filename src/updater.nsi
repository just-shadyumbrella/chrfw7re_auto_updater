!include MUI2.nsh
!include x64.nsh
!include StrFunc.nsh
!include FileFunc.nsh
!include LogicLib.nsh

!define NAME "Chromium-for-windows-7-REWORK"
!define BetaSources "https://api.github.com/repos/e3kskoy7wqk/Chromium-for-windows-7-REWORK/releases"
!define ReleaseSources "${BetaSources}/latest"
!define ChromiumInstallPath "$LOCALAPPDATA\Chromium\Application"

Name ${NAME}
BrandingText " "
OutFile "..\out\updater.exe"
Icon updater.ico
RequestExecutionLevel user
SetCompressor /SOLID lzma
AutoCloseWindow true

# Just user /S as silent updater
!define MUI_ICON updater.ico
!define MUI_ABORTWARNING
!define MUI_PAGE_CUSTOMFUNCTION_SHOW InstFilesShow
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE English

Function InstFilesShow
	GetDlgItem $0 $HWNDPARENT 2
	EnableWindow $0 1
FunctionEnd

Var CommandArgs
Var BinaryVersion
Var Channel
Var Sources
Var Prefix
Var TargetInstaller
Var Index
Var BrowserDownloadUrl

${StrStr}
${StrTrimNewLines}

!macro jq File Query Output Return
	; DetailPrint 'jq -r "${Query}" ${File}'
	nsExec::ExecToStack /OEM 'jq -r "${Query}" ${File}'
	Pop ${Return}
	Pop ${Output}
	${StrTrimNewLines} ${Output} ${Output}
	; nsExec::ExecToLog /OEM 'jq -r "${Query}" ${File}'
!macroend

Section
	w7tbp::Start
	InitPluginsDir
	SetOutPath $PLUGINSDIR

	${GetFileVersion} "${ChromiumInstallPath}\chrome.exe" $BinaryVersion
	IfErrors +2
	DetailPrint "Installed Version: $BinaryVersion"

	File ..\bin\aria2.conf
	File ..\bin\aria2c.exe
	File ..\bin\curl.exe
	File ..\bin\jq.exe

	${GetParameters} $CommandArgs
	${GetOptions} "$CommandArgs" "/channel=" $Channel

	${If} $Channel == "beta"
		DetailPrint "Channel: Beta"
		StrCpy $Sources "${BetaSources}"
	${Else}
		DetailPrint "Channel: Release"
		StrCpy $Sources "${ReleaseSources}"
	${EndIf}

	DetailPrint "Fetching: $Sources"
	nsExec::ExecToStack /OEM "aria2c.exe --conf-path=aria2.conf $Sources -o sources.json"
	Pop $R0

	${If} $R0 != 0
		nsExec::Exec "curl $Sources -o sources.json"
		!insertmacro jq "sources.json" ".message" $R0 $R1
		MessageBox MB_ICONSTOP $R0
		Goto Finish
	${EndIf}

	${If} $Channel == "beta"
		StrCpy $Prefix ".[0]"
	${Else}
		StrCpy $Prefix ""
	${EndIf}

	!insertmacro jq "sources.json" "$Prefix.tag_name" $R0 $R1

	${If} $R0 == $BinaryVersion
		DetailPrint "${NAME} is up to date."
		${GetOptions} "$CommandArgs" "/force" $R0

		${If} ${Errors}
			Goto Finish
		${EndIf}
	${EndIf}

	${If} ${RunningX64}
		StrCpy $TargetInstaller "mini_installer_x64.exe"
	${Else}
		StrCpy $TargetInstaller "mini_installer.exe"
	${EndIf}

	StrCpy $Index 0

	${Do}
		!insertmacro jq "sources.json" "$Prefix.assets[$Index].browser_download_url | select( . != null )" \
			$BrowserDownloadUrl $R1

		${StrStr} $0 $BrowserDownloadUrl $TargetInstaller

		${If} $0 != ""
			${Break}
		${EndIf}

		IntOp $Index $Index + 1
	${LoopUntil} $BrowserDownloadUrl == ""

	; ExecWait "explorer.exe ."

	DetailPrint "Downloading update..."
	nsExec::Exec "aria2c.exe --conf-path=aria2.conf $BrowserDownloadUrl -o update.exe"

	${GetOptions} "$CommandArgs" "/force" $R0

	${IfNot} ${Errors}
		DetailPrint "Forced install: Removing current Chromium installation..."
		${GetOptions} "$CommandArgs" "/clearuserdata" $R1

		${IfNot} ${Errors}
			DetailPrint "Forced install: With user data..."
			StrCpy $R1 " --delete-profile"
		${EndIf}

		ReadRegStr $R0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Chromium" "UninstallString"
		nsExec::Exec "$R0 --force-uninstall$R1"
	${EndIf}

	Sleep 10000
	DetailPrint "Installing update..."
	nsExec::Exec "update.exe"

	Finish:
	GetDlgItem $0 $HWNDPARENT 1
	EnableWindow $0 1
	GetDlgItem $0 $HWNDPARENT 2
	EnableWindow $0 0
	DetailPrint "Auto close in 3..."
	Sleep 1000
	DetailPrint "Auto close in 2..."
	Sleep 1000
	DetailPrint "Auto close in 1..."
	Sleep 1000
SectionEnd

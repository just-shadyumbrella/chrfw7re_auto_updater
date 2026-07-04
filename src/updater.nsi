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
BrandingText ""
OutFile "..\out\updater.exe"
Icon updater.ico
RequestExecutionLevel user
SetCompressor /SOLID lzma
ShowInstDetails show

# Just user /S as silent updater
!define MUI_ICON updater.ico
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE English

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
	File ..\bin\jq.exe

	${GetParameters} $CommandArgs
	${GetOptions} "$CommandArgs" "--channel=" $Channel

	${If} $Channel == "beta"
		DetailPrint "Channel: Beta"
		StrCpy $Sources "${BetaSources}"
	${Else}
		DetailPrint "Channel: Release"
		StrCpy $Sources "${ReleaseSources}"
	${EndIf}

	DetailPrint "Fetching: $Sources"
	nsExec::Exec "aria2c.exe --conf-path=aria2.conf $Sources -o sources.json"

	${If} $Channel == "beta"
		StrCpy $Prefix ".[0]"
	${Else}
		StrCpy $Prefix ""
	${EndIf}

	!insertmacro jq "sources.json" "$Prefix.tag_name" $R0 $R1

	${If} $R0 == $BinaryVersion
		DetailPrint "${NAME} is up to date."
		Goto Finish
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

	${GetOptions} "$CommandArgs" "--force" $R0

	${IfNot} ${Errors}
		DetailPrint "Forced install: Removing current Chromium installation..."
		ReadRegStr $R0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Chromium" "UninstallString"
		ExecWait "$R0 --force-uninstall"
	${EndIf}

	; ExecWait "explorer.exe ."

	DetailPrint "Downloading update..."
	nsExec::Exec "aria2c.exe --conf-path=aria2.conf $BrowserDownloadUrl -o update.exe"
	DetailPrint "Installing update..."
	nsExec::Exec "update.exe"

	Finish:
SectionEnd

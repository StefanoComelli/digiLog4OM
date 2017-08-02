; ***************
; * digiLog4OM  *
; * v1.0.0      *
; * © IZ3XNJ    *
; ***************

; +------+
; | Main |
; +------+
	#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
	;#Warn ; Enable warnings to assist with detecting common errors. To use only in debug
	SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
	#Persistent ; only one copy running allowed
	
	#Include Class_SQLiteDB.ahk

	version := "1.0.0"   
	
	; config
	Gosub, Config

	; setup
	Gosub, Setup

	; setup tray menu
	Gosub, SetupTrayMenu

	; show about splash screen
	Gosub, about
	
	; TrayTip
	TrayTip, digiLog4OM, digiLog4OM © IZ3XNJ, %traySecs%, 17

	if !IsAppRunning(true)
		ExitApp
	else
	{

		; start
		Gosub, StartDB
		if (isFldigi())
			Gosub, setupComm
		
		if (autoSound = "Y")
			Gosub, SetupAudio
	
		Gosub, StartOmniRig
		
		; events
		if (isFldigi())
			OnClipboardChange("ClipChanged")
		
		OnExit, EndApp
		
		; timer
		SetTimer, CtrlApps, %ctrlAppsMsecs%
		
		; read frequency for the first time
		if (autoSound = "Y")
			Gosub, ReadFreq
	} ; else - if !IsAppRunning(true)
return

; +-------+
; | Setup |
; +-------+
Setup:
	; forced windows activation
	#WinActivateForce 
	; the window's title must start with the specified WinTitle to be a match
	SetTitleMatchMode, 1
	; invisible windows are "seen" by the script
	DetectHiddenWindows, On 

	flgChangedMode := false
	
	; setup control's name
	lblLog4OM = Log4OM [User Profile:
	lblCommunicator = Log4OM Communicator
	lblFldigi = fldigi ver
	lblJtAlert = JTAlert
	
	if (isFldigi())
	{
		; clsNNTab
		clsNNTab := GetLog4OmCtrl("QSO Information (F7)")
		if (clsNNTab = "")
		{
			MsgBox, 16, digiLog4OM © IZ3XNJ, Error in clsNNTab
			ExitApp
		}

		; clsNNMode
		clsNNMode := GetLog4OmCtrl("SSB")
		if (clsNNMode = "")
		{
			MsgBox, 16, digiLog4OM © IZ3XNJ, Error in clsNNMode
			ExitApp
		}

		ctrlOutbound = WindowsForms10.BUTTON.app.0.39490e2_r12_ad13
		ctrlInbound = WindowsForms10.BUTTON.app.0.39490e2_r12_ad12
	}
return

; +--------+
; | Config |
; +--------+
Config:
	
	; read mode from command line
	if 0 < 1
	{
		MsgBox, 16, digiLog4OM © IZ3XNJ, No start params
		ExitApp
	}

	mode = %1%
	StringUpper, mode, mode

	if  (!isFlDigi() and !isJtAlert())
	{
		MsgBox, 16, digiLog4OM © IZ3XNJ, Wrong start param
		ExitApp
	}

	; read from digiLog4OM.ini
	
	; [config]
	
	; yourCall
	IniRead, yourCall, digiLog4OM.ini, config, yourCall, UNDEF_INI
	if (yourCall = "UNDEF_INI")
	{
		MsgBox, 16, digiLog4OM © IZ3XNJ, Error in digiLog4OM.ini`nyourCall
		Gosub, SetupLog4OM 
	}
	
	; clsNNCall
	IniRead, clsNNCall, digiLog4OM.ini, config, clsNNCall, UNDEF_INI
	if (clsNNCall = "UNDEF_INI")
	{
		MsgBox, 16, digiLog4OM © IZ3XNJ, Error in digiLog4OM.ini`nclsNNCall
		Gosub, SetupLog4OM 
	}
	
	;traySecs
	IniRead, traySecs, digiLog4OM.ini, config, traySecs, UNDEF_INI
	if (traySecs = "UNDEF_INI")
	{
		traySecs := 1
		IniWrite, %traySecs%, digiLog4OM.ini, config, traySecs
	}

	;ctrlAppsMsecs
	IniRead, ctrlAppsMsecs, digiLog4OM.ini, config, ctrlAppsMsecs, UNDEF_INI
	if (ctrlAppsMsecs = "UNDEF_INI")
	{
		ctrlAppsMsecs := 5000
		IniWrite, %ctrlAppsMsecs%, digiLog4OM.ini, config, ctrlAppsMsecs
	}

	; [sound]
	
	; autoSound
	IniRead, autoSound, digiLog4OM.ini, sound, autoSound, N

	if (autoSound = "Y")
	{
		; soundCard
		IniRead, soundCard, digiLog4OM.ini, sound, soundCard, UNDEF_INI
		if (soundCard = "UNDEF_INI")
		{
			MsgBox, 16, digiLog4OM © IZ3XNJ, Error in digiLog4OM.ini`nsoundCard
			ExitApp
		}
		
		; volStep
		IniRead, volStep, digiLog4OM.ini, sound, volStep, UNDEF_INI
		if (volStep = "UNDEF_INI")
		{
			volStep := 1
			IniWrite, %volStep%, digiLog4OM.ini, config, volStep
		}
	
		; autoMax
		IniRead, autoMax, digiLog4OM.ini, sound, autoMax, N

		; volDisplayTime
		IniRead, volDisplayTime, digiLog4OM.ini, sound, volDisplayTime, UNDEF_INI
		if (volDisplayTime = "UNDEF_INI")
		{
			volDisplayTime := 2000
			IniWrite, %volDisplayTime%, digiLog4OM.ini, config, volDisplayTime
		}
	}

	; [autoSpot]
	
	; autoSpot
	IniRead, autoSpot, digiLog4OM.ini, spot, autoSpot, N

	if (autoSpot = "Y")
	{
		; sweetSpot
		IniRead, sweetSpot, digiLog4OM.ini, spot, sweetSpot, UNDEF_INI
		if (sweetSpot = "UNDEF_INI")
		{
			sweetSpot := 1000
			IniWrite, %sweetSpot%, digiLog4OM.ini, spot, sweetSpot
		}
	}
return

; +-----------+
; | setupComm |
; +-----------+
setupComm:
	; setup Log4oM communicator
	; bring it to front
	WinActivate, %lblCommunicator%

	; click Inbound & outbound buttons
	ControlClick, %ctrlOutbound%, %lblCommunicator%
	ControlClick, %ctrlInbound%, %lblCommunicator%

	; minimize Log4oM communicator
	WinMinimize, %lblCommunicator%
return

; +--------+
; | EndApp |
; +--------+
EndApp:
	
	; delete timer
	SetTimer, CtrlApps, Delete 

	gosub, Shutdown
	
	if (flgChangedMode)
	{
		Gosub, ReadFreq
		if (freq<14000)
			;PM_SSB_L = 67108864 (&H4000000)
			Rig.Mode := 67108864	
		else
			;PM_SSB_U = 33554432 (&H2000000)
			Rig.Mode := 33554432	
	}	
	
	if (isFldigi())
	{
		; activates the window  and makes it foremost
		WinActivate, %lblLog4OM% 
		; click CLR button to clear previous call
		ControlClick, CLR, %lblLog4OM% 
	}

	Gosub, StopOmniRig

	ExitApp
return

; +----------+
; | CtrlApps |
; +----------+
CtrlApps:
if !IsAppRunning(false)
	Goto, EndApp
return

; +---------------
; | IsAppRunning |
; +--------------+
IsAppRunning(bMsg)
{
	global
	
	; suspend timer
	SetTimer, CtrlApps, Off 
	
	; check if needed Apps are running
	
	; check Log4OM running
	IfWinNotExist, Log4OM Communicator
	{
		if (bMsg)
			MsgBox, 16, digiLog4OM © IZ3XNJ, Log4OM not running
		else
			Gosub, Shutdown
		return false
	}	
	else
	{
		if (isFldigi())
			; check if FlDigi is running
			IfWinNotExist, %lblFldigi%
			{
				if (bMsg)
					MsgBox, 16, digiLog4OM © IZ3XNJ, FlDigi not running
				else
					Gosub, Shutdown
				return false
			}

		if (isJtAlert())
			; check if jtAlert is running
			IfWinNotExist, %lblJtAlert%
			{
				if (bMsg)
					MsgBox, 16, digiLog4OM © IZ3XNJ, JTAlert not running
				else
					Gosub, Shutdown
				return false
			}
	}
	; restart timer
	SetTimer, CtrlApps, On 

	return true
}

; +-------------+
; | ClipChanged |
; +-------------+
ClipChanged(Type) 
{
	global 
	local callsign

	; suspend timer
	SetTimer, CtrlApps, Off 
	
	; this event raise up when clipoard changes
	;  type = 1  means clipboard contains something that can be expressed as text 
	; (this includes files copied from an Explorer window)
	if (Type = 1)
	{
		; convert to upper case
		callsign = %clipboard%
		StringUpper, callsign, callsign
		
		; check if the text in clipboard could be a callsign
		if isCallsign(callsign)
		{			
			; activates the window  and makes it foremost
			WinActivate, %lblLog4OM% 
			
			; read prevoius call
			ControlGetText, prevCall, %clsNNCall%, %lblLog4OM%  

			; only if different
			if (prevCall != callsign)
			{	
				; tray
				TrayTip, digiLog4OM, %callsign%, %traySecs%, 17
				
				; click CLR button to clear previous call
				ControlClick, CLR, %lblLog4OM% 
				
				; copy clipboard to the Callsign field
				ControlSetText, %clsNNCall%, %callsign%, %lblLog4OM% 
			} ; if (prevCall != callsign)
			
			; QSO Information tab {F7} -> Push QSO Information Tab
			ControlSend, %clsNNTab%, {F7}, %lblLog4OM%  
		} ; if isCallsign(callsign)
	} ; if (Type = 1)
	
	; restart timer
	SetTimer, CtrlApps, On 
	return
}

; +------------+
; | isCallsign |
; +------------+
isCallsign(call)
{
	global yourCall

	; check if the text in clipboard could be a callsign
	
	; if the clipboard contains tabs or spaces, is not a callsign
	if call contains  %A_Space%, %A_Tab%
		return false
	
	; if it is too long or too short, is not a callsign
	if (StrLen(call) > 13 or StrLen(call) < 3)
		return false
	
	; if it is your call, I doubt you are doing a QSO with yourself
	if (call == yourCall)
		return false
	
	return true
}

; +------------;
; | SetupAudio |
; +------------;
SetupAudio:
	maxVol := 0
	defVol := 0
	SoundGetWaveVolume, volWave, %soundCard%
	; volume up & down via mouse wheel
	HotKey, WheelUp, volUp       
	HotKey, WheelDown, volDown
	Hotkey, MButton, showVol
return

; +---------+
; | showVol |
; +---------+
showVol:
	; mouse left only if on Tray menu icon 
	#If MouseIsOver("ahk_class Shell_TrayWnd")
	SoundGetWaveVolume, volWave, %soundCard%
	Gosub, SetSoundInfo
return

; +-------+
; | volUp |
; +-------+
volUp:
	; mouse wheel only if on Tray menu icon 
	#If MouseIsOver("ahk_class Shell_TrayWnd")
	SoundSetWaveVolume, +%volStep%, %soundCard%
	SoundGetWaveVolume, volWave, %soundCard%
	Gosub, FixVol
	Gosub, SetSoundInfo
return

; +---------+
; | volDown |
; +---------+
volDown:
	; mouse wheel only if on Tray menu icon 
	#If MouseIsOver("ahk_class Shell_TrayWnd")
	SoundSetWaveVolume, -%volStep%, %soundCard%
	SoundGetWaveVolume, volWave, %soundCard%
	Gosub, FixVol
	Gosub, SetSoundInfo
return

; +----------------------------+
; | OmniRigEngine_ParamsChange |
; +----------------------------+
OmniRigEngine_ParamsChange(RigNumber, Params)
{
	; triggered when radio change via Omnirig
	Gosub, ReadFreq
}

; +----------+
; | ReadFreq |
; +----------+
ReadFreq:
	; read rx frequency
	freq := Rig.GetRxFrequency / 1000
	; if on TX, rx frequency is 0, so read from tx fequency
	if (freq = 0)
			freq := Rig.GetTxFrequency / 1000	
	; which band ?
	nBand := GetBand(freq)

	; is band changed?
	if (nBand <> band)
	{
		band := nBand
		
		; goes in PM_DIG_U = 134217728 (&H8000000)
		Rig.Mode := 134217728 

		if (autoSound = "Y")
		{
			maxVol := GetMaxVol(band)
			defVol := GetDefVol(band)
			if (isFldigi())
			{
				defFreq := GetDefFreq(band)
				Rig.SetSimplexMode(defFreq * 1000)
			}
			volWave := defVol
			SoundSetWaveVolume, %volWave%, %soundCard%
			Gosub, SetSoundInfo
		} ; if (autoSound = "Y")
		if (isFldigi())
		{
			; activates the window  and makes it foremost
			WinActivate, %lblLog4OM% 
			; click CLR button to clear previous call
			ControlClick, CLR, %lblLog4OM% 
		}
	} ; if (nBand <> band)
return

; +--------+
; | FixVol |
; +--------+
FixVol:
	; set audio level to the max allowed per band 
	if (autoMax = "Y" and volWave > maxVol)
	{
		volWave := maxVol
		SoundSetWaveVolume, %volWave%, %soundCard%
	}
return

; +---------+
; | GetBand |
; +---------+
GetBand(vFreq)
{
	; retrieve band by frequency
	global audioData
	
	vBand = NO_HAM
	for index, element in audioData
		if (element.isInBand(vFreq))
		{
			vBand := element.band
			break
		}
	return vBand
}

; +-----------+
; | GetMaxVol |
; +-----------+
GetMaxVol(vBand)
{
	; retrieve default audio level for band
	global audioData
	
	vMaxVol := 0
	for index, element in audioData
		if (element.band = vBand)
		{
			vMaxVol := element.Maxlevel
			break
		}
	return vMaxVol
}

; +-----------+
; | GetDefVol |
; +-----------+
GetDefVol(vBand)
{
	; retrieve default audio level for band
	global audioData
	
	vDefVol := 0
	for index, element in audioData
		if (element.band = vBand)
		{
			vDefVol := element.defLevel
			break
		}
	return vDefVol
}

; +------------+
; | GetDefFreq |
; +------------+
GetDefFreq(vBand)
{
	; retrieve default audio level for band
	global audioData
	
	vDefFreq := 0
	for index, element in audioData
		if (element.band = vBand)
		{
			vDefFreq := element.defFreq
			break
		}
	return vDefFreq
}

; +-------------+
; | StopOmniRig |
; +-------------+
StopOmniRig:
	; stop OmniRig engine
	Rig := ""
	OmniRigEngine := ""
return

; +--------------+
; | StartOmniRig |
; +--------------+
StartOmniRig:
	; start OmniRig engine
	OmniRigEngine := ComObjCreate("OmniRig.OmniRigX") 
	Rig := OmniRigEngine.Rig1
	freq := 0
	band := 0
	
	; goes in PM_DIG_U = 134217728 (&H8000000)
	Rig.Mode := 134217728 
	flgChangedMode := true
	
	; Connects events to corresponding script functions with the prefix "OmniRigEngine_".
	ComObjConnect(OmniRigEngine, "OmniRigEngine_")
	
	Gosub, ReadFreq	
return

; +--------------+
; | SetSoundInfo |
; +--------------+
SetSoundInfo:
	; display sound infos
	if (autoSound = "Y")
	{
		sFreq := Format("{1:0.2f}",freq)
		SoundGetWaveVolume, volWave, %soundCard%
		sWave := Format("{1:0.0f}", volWave)
		sMaxWave := Format("{1:0.0f}", maxVol)
		sDefWave := Format("{1:0.0f}", defVol)
		Progress, 1:%volWave%, Lev:%sWave%`% Max:%sMaxWave%`% Def:%sDefWave%`%, %band% - %sFreq%, digiLog4OM - %mode% 
		SetTimer, volBarOff, %volDisplayTime%
	}
return

; +---------+
; | StartDB |
; +---------+
StartDB:
	; open connection to SQLITE db
	global MyDb
	
	MyDB := New SQLiteDB
	DBFileName := A_ScriptDir . "\digiLog4OM.sqlite"
	If !MyDB.OpenDB(DBFileName) 
	{
		MsgBox, 16, digiLog4OM © IZ3XNJ, % "StartDB:`t" . MyDB.ErrorMsg . "`nCode:`t" . MyDB.ErrorCode
		ExitApp
	}
	Gosub, readDB
	Gosub, StopDB
return

; +--------+
; | StopDB |
; +--------+
StopDB:
	; close connection to DB
	global MyDb
	MyDB.CloseDB()
return

; +---------+
; | setSpot |
; +---------+
setSpot:
	; set sweet spot frequency
	if (autoSpot="Y")
	{
		InputBox, spotFreq , FlDigi QSY, Frequency
		if (spotFreq > sweetSpot / 1000)
		{
			newFreq := spotFreq * 1000 - sweetSpot		
			Rig.SetSimplexMode(newFreq)
		}
	}
return

; +------------+
; | ChangeFreq |
; +------------+
ChangeFreq(delta)
{
	; shift frequency from actual adding delta
	global Rig
	
	dFreq := Rig.GetRxFrequency + delta
	Rig.SetSimplexMode(dFreq)
}

; +-------+
; | oneUp |
; +-------+
oneUp:
	; change frequency one kHz up
	ChangeFreq(1000)
return

; +---------+
; | oneDown |
; +---------+
oneDown:
	; change frequency one kHz down
	ChangeFreq(-1000)
return

; +---------------+
; | SetupTrayMenu |
; +---------------+
SetupTrayMenu:
	; set tray Icon  & menues
	Menu, Tray, Icon, digiLog4OM.ico
	menu, Tray, NoStandard
	
	if (isFldigi() and autoSpot="Y")
	{
		Menu, mnuFreq, Add, Fldigi QSY, setSpot
		Menu, mnuFreq, Add, +1 Khz, oneUp
		Menu, mnuFreq, Add, -1 Khz, oneDown
		Menu, mnuFreq, Add, Default, ResetDefFreq
		Menu, Tray, add, Frequency, :mnuFreq
		
		;Menu, mnuMode, Add, PSK31, SetPSK31
		;Menu, Tray, add, Mode, :mnuMode	
		}
	
	if (autoSound = "Y")
	{
		Menu, mnuAudio, Add, Default, ResetDefAudio
		Menu, mnuAudio, Add, Max, SetMaxAudio
		Menu, Tray, add, Audio, :mnuAudio
	}
	
	Menu, mnuSys, Add, ReRead Ini, ReReadIni
	Menu, mnuSys, Add, Setup..., SetupLog4OM
	Menu, mnuSys, Add, About..., about
	Menu, Tray, add, System, :mnuSys

	Menu, Tray, Add, Exit, EndApp
return

; +---------------+
; | ResetDefAudio |
; +---------------+
ResetDefAudio:
	if (autoSound = "Y")
	{
		volWave := defVol
		SoundSetWaveVolume, %volWave%, %soundCard%
		Gosub, SetSoundInfo
	} ; if (autoSound = "Y")
return

; +-------------+
; | SetMaxAudio |
; +-------------+
SetMaxAudio:
	if (autoSound = "Y")
	{
		volWave := maxVol
		SoundSetWaveVolume, %volWave%, %soundCard%
		Gosub, SetSoundInfo
	} ; if (autoSound = "Y")
return

; +--------------+
; | ResetDefFreq |
; +--------------+
ResetDefFreq:
	defFreq := GetDefFreq(band)
	Rig.SetSimplexMode(defFreq * 1000)
return

; +-------------+
; | MouseIsOver |
; +-------------+
MouseIsOver(WinTitle) 
{
	; detect if winndow is over a specified window
    MouseGetPos,,, Win
    return WinExist(WinTitle . " ahk_id " . Win)
}

; +--------+
; | readDB |
; +--------+
readDB:
	; read audio per band info from database to memory table
	audioData := Object()
	tSQL = SELECT band, startFreq, endFreq, maxLevel, defLevel, defFreq FROM tblAudioBand; 

	If (!MyDB.GetTable(tSQL, result))
			MsgBox, 16, digiLog4OM © IZ3XNJ, %  "readDB:`t" . MyDB.ErrorMsg . "`nCode:`t" . MyDB.ErrorCode
	
	If (result.HasRows) 
		If (result.Next(tRow) = 1) 
			Loop 
			{
				dBand := new AudioBand()
				dBand.band := tRow[1]
				dBand.startFreq := tRow[2]
				dband.endFreq := tRow[3]
				dBand.maxLevel := tRow[4]
				dBand.defLevel := tRow[5]
				dBand.defFreq := tRow[6]
				audioData.Insert(dBand)
				tRC := result.Next(tRow)
			} 
			Until (tRC < 1)
return

; +-------+
; | about |
; +-------+
about:
	; splash
	SplashTextOn, 200, 50, digiLog4OM © IZ3XNJ, digiLog4OM`nv%version% %yourCall% - %mode%
	Sleep, 2000
	SplashTextOff
return

; +-----------+
; | AudioBand |
; +-----------+
Class AudioBand
{
	; Class used for audio leve per band info
	band := ""
	startFreq := 0
	endFreq := 0
	maxLevel := 0
	defLevel := 0
	defFreq := 0
	; +----------+
	; | isInBand |
	; +----------+
	isInBand(freq)
	{
		if (freq >= this.startFreq and freq <= this.endFreq)
			return true
		else
			return false
	}
}

; +-----------+
; | volBarOff |
; +-----------+
volBarOff:
	; disale OSD timer
	SetTimer, volBarOff, off
	; close OSD
	Progress, 1:Off
return

; +----------+
; | Shutdown |
; +----------+
Shutdown:
	; splash
	SplashTextOn, 200, 25, digiLog4OM © IZ3XNJ, Shutdown in progress...
	Sleep, 1000
	SplashTextOff
return

; +-----------+
; | ReReadIni |
; +-----------+
ReReadIni:
	; splash
	SplashTextOn, 200, 25, digiLog4OM © IZ3XNJ, ReReadIni
	Sleep, 1000
	SplashTextOff

	; config
	Gosub, Config

	; setup tray menu
	Gosub, SetupTrayMenu

	; show about splash screen
	Gosub, about
return

; +----------+
; | isFldigi |
; +----------+
isFldigi()
{
	global mode
	if (mode = "FLDIGI")
		return true
	else
		return false
}

; +-----------+
; | isJtAlert |
; +-----------+
isJtAlert()
{
	global mode
	if (mode = "JTALERT")
		return true
	else
		return false
}

; +-------------+
; | SetupLog4OM |
; +-------------+
SetupLog4OM:

	if (yourCall = "")
	{
		InputBox, yourCall, digiLog4OM © IZ3XNJ, digiLog4OM © IZ3XNJ`nYour Callsign?
		if (yourCall = "")
		{
			MsgBox, 16, digiLog4OM © IZ3XNJ, digiLog4OM © IZ3XNJ`nNo Callsign entered.
			ExitApp
		}

		StringUpper, yourCall, yourCall
		; yourCall
		IniWrite, %yourCall%, digiLog4OM.ini, config, yourCall
	}
	
	MsgBox, 32, digiLog4OM © IZ3XNJ, digiLog4OM © IZ3XNJ`nWrite your own callsign %yourCall% into Log4OM callsign field`nand then click OK here
	
	clsNNCall := GetLog4OmCtrl(yourCall)
	if (clsNNCall <> "")
	{
		; this is callsign field, as it contains  your call sign
		MsgBox, 64, digiLog4OM © IZ3XNJ, digiLog4OM © IZ3XNJ`nCallsign field OK

		; activates the window  and makes it foremost
		WinActivate, %lblLog4OM% 
		; click CLR button to clear previous call
		ControlClick, CLR, %lblLog4OM% 
		
		flgCallsignOk := true
		IniWrite, %clsNNCall%, digiLog4OM.ini, config, clsNNCall
		gosub, ReReadIni
	}
	else
	{
		MsgBox, 16, digiLog4OM © IZ3XNJ, digiLog4OM © IZ3XNJ`nSetup Callsign Field KO
		ExitApp
	}
return

; +---------------+
; | GetLog4OmCtrl |
; +---------------+
GetLog4OmCtrl(txtLbl)
{
	local hwnd
	local controls 
	local txtRead
	
	hWnd := WinExist(lblLog4OM)

	; retrieve all controls in the main window
	WinGet, controls, ControlListHwnd, Log4OM [User Profile:

	; for each control
	Loop, Parse, controls, `n
	{
		; retrieve text from control
		ControlGetText, txtRead,, ahk_id %A_LoopField%
		if (txtRead = txtLbl)
		{
			ctrlName := Control_GetClassNN(hWnd, A_LoopField) 
			break
		}
	} ; Loop, Parse, controls, `n
	return ctrlName
}

; +--------------------+
; | Control_GetClassNN |
; +--------------------+
Control_GetClassNN(hWnd, hCtrl) 
{
	; SKAN: www.autohotkey.com/forum/viewtopic.php?t=49471
	WinGet, CH, ControlListHwnd, ahk_id %hWnd%
	WinGet, CN, ControlList, ahk_id %hWnd%
	Clipboard := CN
	LF:= "`n",  CH:= LF CH LF, CN:= LF CN LF,  S:= SubStr( CH, 1, InStr( CH, LF hCtrl LF ) )
	StringReplace, S, S,`n,`n, UseErrorLevel
	StringGetPos, P, CN, `n, L%ErrorLevel%
	Return SubStr( CN, P+2, InStr( CN, LF, 0, P+2 ) -P-2 )
}

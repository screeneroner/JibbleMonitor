;----------------------------------------------------------------------------------------------------------------------
; This code is free software: you can redistribute it and/or modify  it under the terms of the 
; version 3 GNU General Public License as published by the Free Software Foundation.
; 
; This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY without even 
; the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
; See the GNU General Public License for more details (https://www.gnu.org/licenses/gpl-3.0.html)
;
; WARNING TO USERS AND MODIFIERS
;
; This script contains "Buy me a coffee" links to honor the author's hard work and dedication in creating
; all the features present in this code. Removing or altering these links not only violates the GPL license
; but also disregards the significant effort put into making this script valuable for the community.
;
; If you find value in this script and would like to show appreciation to the author,
; kindly consider visiting the site below and treating the author to a few cups of coffee:
;
; https://www.buymeacoffee.com/screeneroner
;
; Your honor and gratitude is greatly appreciated.
;----------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------
/*
User Guide:

Jibble (https://www.jibble.io/) can sometimes freeze when taking a screenshot. Occasionally, it recovers on its own, 
but other times it stays stuck, which could cause you to miss screenshots and lead to misunderstandings with your employer.

This small utility monitors the Jibble log file to check for recent activity. If no events are recorded for over 20 minutes, 
meaning you might have missed one or more screenshots, you will get a notification in the system tray. 

Monitoring can also be paused if you stop Jibble for a break or at the end of the day by selecting the corresponding option 
from the utility's context menu in the system tray.

You can also turn on alerts for every new event in the Jibble log. 
If you see an error like "Connection error saving screenshot" instead of "Image uploaded," you can try restarting Jibble. 
This usually fixes the issue and helps ensure you only lose a single screenshot.
*/
;----------------------------------------------------------------------------------------------------------------------

#Persistent
#SingleInstance, Force
log_file_path := A_AppData "\Jibble\Jibble\jibble.log"
SetTimer, CheckFile, 1000
prevLastTime := ""
alertShown := false
blinking := false
blinkState := 0
show_events_notifications := true
jibble_monitoring := true

Menu, Tray, Icon, %A_WinDir%\System32\shell32.dll, 273
Menu, Tray, NoStandard
Menu, Tray, Add, Jibble monitoring, ToggleMonitoring
Menu, Tray, Check, Jibble monitoring  ; Initially check the menu item
Menu, Tray, Default, Jibble monitoring
Menu, Tray, Add, Show Jibble Log, ShowLog
Menu, Tray, Add, Events notification, ToggleNotify
Menu, Tray, Check, Events notification  ; Initially check the menu item
Menu, Tray, Add, Buy me a coffee, BuyCoffee
Menu, Tray, Add
Menu, Tray, Add, Exit, ExitApp

CheckFile()
{
    global prevLastTime, alertShown, blinking, show_events_notifications, log_file_path, jibble_monitoring
    if (!jibble_monitoring)
    {
        Menu, Tray, Icon, %A_WinDir%\System32\shell32.dll, 26
        blinking := false
        Menu, Tray, Tip, Jibble: monitoring paused
        return
    }

    if (!blinking)  ; Only reset icon when not blinking
        Menu, Tray, Icon, %A_WinDir%\System32\shell32.dll, 273

    if !FileExist(log_file_path)
        return

    fileContent := []
    Loop, Read, %log_file_path%
        fileContent.Push(A_LoopReadLine)

    lineCount := fileContent.MaxIndex()
    if (lineCount < 1)
        return

    lastLine := fileContent[lineCount]
    if RegExMatch(lastLine, "(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})", match)
    {
        dateTime := match1 . match2 . match3 . match4 . match5 . match6
        now := A_Now
        EnvSub, now, %dateTime%, Minutes
        minutesDiff := now
        extractedText := ""
        if (RegExMatch(lastLine, " - (.*)", textMatch))
        {
            extractedText := textMatch1
            StringReplace, extractedText, extractedText, `n, , All
            extractedText := RegExReplace(extractedText, "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}", "")
            extractedText := Trim(extractedText)
        }

        Menu, Tray, Tip, Jibble: %minutesDiff% mins ago`n%extractedText%

        if (prevLastTime != dateTime)
        {
            prevLastTime := dateTime
            alertShown := false
            blinking := false
            if (show_events_notifications)
                TrayTip, Jibble, %extractedText%`n%match%, 5, 1
        }

        EnvAdd, dateTime, 20, Minutes

        if (A_Now > dateTime)
        {
            if (!alertShown)
            {
                TrayTip, Jibble: Last event older 20 minutes, % extractedText, 5, 2
                alertShown := true
            }
            blinking := true
            SetTimer, BlinkIcon, 500 
        }
        else
        {
            if (!blinking)  ; Only reset icon when not blinking
            {
                Menu, Tray, Icon, %A_WinDir%\System32\shell32.dll, 273
                SetTimer, BlinkIcon, Off
            }
            blinking := false
        }
    }
}

BlinkIcon()
{
    global blinkState, blinking
    if (blinking)
    {
        Menu, Tray, Icon, %A_WinDir%\System32\shell32.dll, % (blinkState ? 50 : 78)
        blinkState := !blinkState
    }
}

ShowLog()
{
    global log_file_path
    Run, %log_file_path%, , UseErrorLevel
}

ToggleNotify()
{
    global show_events_notifications
    show_events_notifications := !show_events_notifications
    if (show_events_notifications)
        Menu, Tray, Check, Events notification
    else
        Menu, Tray, Uncheck, Events notification
}

ToggleMonitoring()
{
    global jibble_monitoring
    jibble_monitoring := !jibble_monitoring
    if (jibble_monitoring)
        Menu, Tray, Check, Jibble monitoring
    else
        Menu, Tray, Uncheck, Jibble monitoring
}

BuyCoffee()
{
    Run, https://www.buymeacoffee.com/screeneroner
}

ExitApp()
{
    ExitApp
}


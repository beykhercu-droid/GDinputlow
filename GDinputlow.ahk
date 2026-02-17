#NoEnv
#SingleInstance Force
#Persistent
#KeyHistory 0
ListLines Off
SetBatchLines -1
SetMouseDelay, -1
Process, Priority, , High

; ============================================================
; Geometry Dash - Input low-latency (AutoHotkey v1)
; Mejoras:
; - Inicialización y cleanup robustos
; - Guardado de máscara de afinidad original
; - Restauración segura de timer/afinidad al salir
; - Hotkeys de utilidad: F6 reset récord, F7 abre log
; ============================================================

global g_TimerAdjusted := false
global g_MinLag := 9999.0
global g_LogFile := A_ScriptDir . "\records_gd.txt"
global g_Qpf := 0
global g_UseAffinity := true
global g_AffinityMask := 128 ; CPU 7 (bit 7)
global g_hProc := 0
global g_OldProcessMask := 0
global g_OldSystemMask := 0
global g_HasOldAffinity := false

OnExit("Cleanup")
Init()
return

Init() {
    global g_TimerAdjusted, g_Qpf, g_UseAffinity, g_AffinityMask
    global g_hProc, g_OldProcessMask, g_OldSystemMask, g_HasOldAffinity

    ; Solicitar 0.5ms (5000 * 100ns) si el SO lo permite
    local currentRes := 0
    local ntstatus := DllCall("ntdll.dll\NtSetTimerResolution", "UInt", 5000, "UInt", 1, "UInt*", currentRes, "UInt")
    if (ntstatus = 0)
        g_TimerAdjusted := true

    if !DllCall("QueryPerformanceFrequency", "Int64*", qpf)
        qpf := 0
    g_Qpf := qpf

    g_hProc := DllCall("GetCurrentProcess", "Ptr")

    ; Guardar afinidad original antes de cambiarla
    if (g_UseAffinity && g_hProc) {
        ok := DllCall("GetProcessAffinityMask", "Ptr", g_hProc, "Ptr*", processMask, "Ptr*", systemMask)
        if (ok) {
            g_OldProcessMask := processMask
            g_OldSystemMask := systemMask
            g_HasOldAffinity := true
        }

        DllCall("SetProcessAffinityMask", "Ptr", g_hProc, "Ptr", g_AffinityMask)
    }
}

#IfWinActive ahk_exe GeometryDash.exe

*sc11C::
    Critical
    global g_Qpf, g_MinLag

    if (g_Qpf > 0)
        DllCall("QueryPerformanceCounter", "Int64*", t1)

    ; Botón izquierdo DOWN
    DllCall("user32.dll\mouse_event", "UInt", 0x0002, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0)

    if (g_Qpf > 0) {
        DllCall("QueryPerformanceCounter", "Int64*", t2)
        lag := (t2 - t1) * 1000.0 / g_Qpf

        if (lag > 0.0001 && lag < g_MinLag) {
            g_MinLag := Round(lag, 3)
            SetTimer, SaveAsync, -10
        }
    }
return

*sc11C Up::
    ; Botón izquierdo UP
    DllCall("user32.dll\mouse_event", "UInt", 0x0004, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0)
return

; Reset manual del récord
~*F6::
    global g_MinLag
    g_MinLag := 9999.0
    SetTimer, SaveAsync, -10
return

; Abrir archivo de récord
~*F7::
    global g_LogFile
    if FileExist(g_LogFile)
        Run, notepad.exe "%g_LogFile%"
return

SaveAsync:
    global g_LogFile, g_MinLag
    FileDelete, %g_LogFile%
    if (g_MinLag < 9999.0)
        FileAppend, %g_MinLag%ms, %g_LogFile%
    else
        FileAppend, sin_record, %g_LogFile%
return

~*F4::
    ExitApp
return

#IfWinActive

Cleanup(exitReason, exitCode) {
    global g_TimerAdjusted, g_hProc, g_HasOldAffinity, g_OldProcessMask

    ; Restaurar afinidad original si se guardó
    if (g_hProc && g_HasOldAffinity && g_OldProcessMask)
        DllCall("SetProcessAffinityMask", "Ptr", g_hProc, "Ptr", g_OldProcessMask)

    ; Desactivar solicitud de alta resolución del timer
    if (g_TimerAdjusted) {
        local currentRes := 0
        DllCall("ntdll.dll\NtSetTimerResolution", "UInt", 5000, "UInt", 0, "UInt*", currentRes, "UInt")
    }
}

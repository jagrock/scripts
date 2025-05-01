#SingleInstance
check_interval_min := 2
minimum_idle_min := 8
check_interval_offHours_min := 30

check_interval_ms := check_interval_min * 60 * 1000
minimum_idle_ms := minimum_idle_min * 60 * 1000
check_interval_offHours_ms := check_interval_offHours_min * 60 * 1000

hourStart := 7
hourEnd := 16

Loop {
    if (A_Hour >= hourStart and A_Hour <= hourEnd) {
        if (A_TimeIdle > minimum_idle_ms) {
            SetCapsLockState !GetKeyState("CapsLock", "T")
            SetNumLockState !GetKeyState("NumLock", "T")
            SetScrollLockState 1
            Sleep 100
            SetCapsLockState !GetKeyState("CapsLock", "T")
            SetNumLockState !GetKeyState("NumLock", "T")
            SetScrollLockState 0
        }
        Sleep check_interval_ms
    }
    else {
        Sleep check_interval_offHours_ms
    }

}
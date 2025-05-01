check_interval_min := 2
minimum_idle_min := 8

check_interval_ms := check_interval_min * 60 * 1000
minimum_idle_ms := minimum_idle_min * 60 * 1000

Loop {
    if (A_Hour >= 8 && A_Hour <= 16) {
        
        if (A_TimeIdle > minimum_idle_ms) {
            SetScrollLockState "On"
            Sleep 50
            SetScrollLockState "Off"
        }
        Sleep check_interval_ms
    }
    
}
function Get-ADUserIsDisabled {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [Int] $UserAccountControl
    )
    
    begin {}
    
    process {
        switch ($UserAccountControl -band 2) {
            2 { $true }
            Default { $false}
        }
    }
    
    end {}
}
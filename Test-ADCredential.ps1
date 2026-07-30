function Test-ADCredential {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [PSCredential] $Credential,

        # Parameter help description
        [Parameter()]
        [string] $Server
    )
    
    begin {
        $assembliesLoaded = [AppDomain]::CurrentDomain.GetAssemblies()
        $assembliesRequired = @(
            'System.DirectoryServices.AccountManagement'
        )
        foreach ($assembly in $assembliesRequired) {
            if (($assembliesLoaded -match 'System.DirectoryServices.AccountManagement').Count -eq 0) {
                #Loading Required Assembly
                Write-Verbose "Loading Required Assembly:  $assembly"
                try {
                    Add-Type -AssemblyName $assembly
                }
                catch {
                    Write-Warning "Failed to Load Assembly:  $assembly"
                    $_ | Write-Error
                }
                
            }
        }
    }
    
    process {
        if ($PSBoundParameters.ContainsKey('Credential') -eq $false) {
            Write-Warning "No Credential Preovided"
            return $null
        }


        $dsContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
        if ($PSBoundParameters.ContainsKey('Server')) {
            $dsContextName = $Server
        } else {
            $dsContextName = $env:USERDNSDOMAIN
        }
        
        $principleContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($dsContextType, $dsContextName)
        if ( $principleContext.ValidateCredentials($Credential.UserName, ($Credential.GetNetworkCredential().Password)) ) {
            Write-Host "$($Credential.UserName) on $server - Pass" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "$($Credential.UserName) on $server - Fail"
            return $false
        }

    }
    
    end {
        
    }
}
function Get-ADUserUACFlags {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [Alias('UAC')]
        [Int] $UserAccountControl,

        # How to return FLag data
        [Parameter()]
        [ValidateSet('String', 'Array', 'Hashtable')]
        [string] $ReturnType

        <#
        # If Return String, what is the structure
        [Parameter()]
        [ValidateSet('FlagName', 'FlagName:FlagDecimal', 'FlagDecimal')]
        [string] $StringFormat
        #>
    )

    dynamicparam {
        if ($ReturnType -eq 'String') {
            $paramAttr = [System.Management.Automation.ParameterAttribute]@{
                ParameterSetName = 'ReturnString'
                Mandatory        = $true
            }
            $paramValidateSet = [System.Management.Automation.ValidateSetAttribute]::new('FlagName', 'FlagName:FlagDecimal', 'FlagDecimal')

            $attrCol = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $attrCol.Add($paramAttr)
            $attrCol.Add($paramValidateSet)

            $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                'StringFormat', [string], $attrCol
            )

            $paramDict = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
            $paramDict.Add('StringFormat', $dynParam)
            return $paramDict
        }
    }
    
    begin {

        if ($PSBoundParameters.ContainsKey('Debug')) {
            foreach ($param in $PSBoundParameters.Keys) {
                Write-Debug ('{0} : {1}' -f $param, $PSBoundParameters.$param)
            }
        }

        if ($PSBoundParameters.ContainsKey('StringFormat')) {
            $StringFormat = $PSBoundParameters.StringFormat
        }
        <#
        Reference:  https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/useraccountcontrol-manipulate-account-properties#useraccountcontrol-values
        #>
        $enumUAC = [ordered]@{
            512      = 'NORMAL_ACCOUNT'
            1        = 'SCRIPT'
            2        = 'ACCOUNTDISABLE'
            8        = 'HOMEDIR_REQUIRED'
            16       = 'LOCKOUT'
            32       = 'PASSWD_NOTREQD'
            64       = 'PASSWD_CANT_CHANGE'
            128      = 'ENCRYPTED_TEXT_PWD_ALLOWED'
            256      = 'TEMP_DUPLICATE_ACCOUNT'
            2048     = 'INTERDOMAIN_TRUST_ACCOUNT'
            4096     = 'WORKSTATION_TRUST_ACCOUNT'
            8192     = 'SERVER_TRUST_ACCOUNT'
            65536    = 'DONT_EXPIRE_PASSWORD'
            131072   = 'MNS_LOGON_ACCOUNT'
            262144   = 'SMARTCARD_REQUIRED'
            524288   = 'TRUSTED_FOR_DELEGATION'
            1048576  = 'NOT_DELEGATED'
            2097152  = 'USE_DES_KEY_ONLY'
            4194304  = 'DONT_REQ_PREAUTH'
            8388608  = 'PASSWORD_EXPIRED'
            16777216 = 'TRUSTED_TO_AUTH_FOR_DELEGATION'
            6710886  = 'PARTIAL_SECRETS_ACCOUNT'
        }
    }
    
    process {
        $flags = [System.Collections.Generic.List[psobject]]::new()
        $flagsHash = [ordered]@{}

        foreach ($flag in $enumUAC.keys) {
            if ($UserAccountControl -band $flag) {
                $flagsHash.add($enumUAC.$flag, $flag)
                $flags.Add([PSCustomObject]@{
                        Flag    = $enumUAC.$flag
                        Decimal = $flag
                    })
            }
        }

        switch ($ReturnType) {
            'Array' { 
                Write-Debug "Returning Array"
                $flags
            }
            'Hashtable' {
                Write-Debug 'Returning Hashtable'
                $flagsHash
            }
            'String' {
                Write-Debug 'Returning String'
                switch ($StringFormat) {
                    'FlagName' {
                        Write-Debug "String Format:  $StringFormat"
                        return $flagsHash.Keys -join ';'
                    }
                    'FlagName:FlagDecimal' {
                        Write-Debug "String Format:  $StringFormat"
                        $stringArray = foreach ($flag in $flags) {
                            '{0}:{1}' -f $flag.Flag, $flag.Decimal
                        }
                        
                        return $stringArray -join ';'
                    }
                    'FlagDecimal' {
                        Write-Debug "String Format:  $StringFormat"
                        return $flagsHash.Values -join ';'
                    }
                    Default {}
                }
            }
        }
    }
    
    end {}
}

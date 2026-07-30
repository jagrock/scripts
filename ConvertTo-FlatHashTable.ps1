function ConvertTo-FlatHashTable {
    [CmdletBinding()]
    param (
        # Input Object
        [Parameter()]
        [object]
        $InputObject,

        # Prefix for Property Name
        [Parameter()]
        [string] $Prefix,

        # Separator for nested property names.  Default value is '.'.
        [Parameter()]
        [string] $Separator = '.',

        # Properties to ignore/exclude from flattening
        [Parameter()]
        [string[]] $ExcludeProperties,

        # Hidden - Current Depth Level
        [Parameter(DontShow)]
        [int] $Level = 0,

        # Hidden - HashTable
        [Parameter(DontShow)]
        [switch] $isNested,

        # How to Handle Arrays
        [Parameter()]
        [ValidateSet('JoinAsText', 'JsonString', 'Expand')]
        [string] $Arrays = 'JoinAsText'
    )
    
    begin {
        

        if ($null -eq $hashObject) {
            Write-Verbose 'Creating ordered hashtable hashObject'
            $hashObject = [ordered]@{}
        }

        $propsExclude = @{
            Length         = $null
            LongLength     = $null
            Rank           = $null
            SyncRoot       = $null
            IsReadOnly     = $null
            IsFixedSize    = $null
            IsSynchronized = $null
            Count          = $null
        }

        if ($PSBoundParameters.ContainsKey('ExcludeProperties')) {
            foreach ($prop in $ExcludeProperties) {
                $propsExclude.Add($prop, $null)
            }
        }
    }
    
    process {
        Write-Verbose "$('-' * 10) Processing Object:  Level $(0 + $Level)"

        foreach ($prop in $InputObject.psobject.Properties) {
            if ($propsExclude.ContainsKey($prop.name)) {
                Write-Verbose "Skipping Excluded Property:  $($prop.name)"
                continue
            }

            $propSeparator = if ($null -ne $Prefix -and $Prefix.Length -gt 0) { $Separator } else { $null }
            $propName = '{0}{1}{2}' -f $Prefix, $propSeparator, $prop.name
            Write-Verbose "PropName:  $propName"

            switch ($prop) {
                { $_.value -is [psobject] } {
                    Write-Verbose "isPSObject:  $propName"
                    $splatConvertToFlatObject = @{
                        InputObject = $prop.Value
                        Prefix      = $propName
                        Separator   = $Separator
                        Level       = $Level + 1
                        isNested    = $true
                    }

                    ConvertTo-FlatHashTable @splatConvertToFlatObject
                }

                { $_.value -is [array] } {
                    Write-Verbose "isArray:  $propName |  Output Type:  $Arrays"
                    switch ($Arrays) {
                        'JoinAsText' {
                            $hashObject.($propName) = ($prop.value | ForEach-Object { $PSItem -join ';' }) -join ','
                        }
                        'JsonString' {
                            $hashObject.($propName) = $prop.value | ConvertTo-Json -Depth 10 -Compress
                        }
                        'Expand' {
                            <#
                            Need to figure out how to Expand (each array item as it's own item)
                            #>
                            Write-Verbose "Expand Option for Arrays... Still a work in Progress.  Will output as string"
                            $hashObject.($propName) = ($prop.value | ForEach-Object { $PSItem -join ';' }) -join ','
                        }
                    }
                }

                Default {
                    Write-Verbose "isDefalut:  $propName"
                    $hashObject.($propName) = $prop.Value
                }
            }            
        }

        if (-not $isNested) {
            $hashObject
        }
        
    }
    
    end {
    }
}

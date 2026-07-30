function ConvertTo-FlatObject {
    [CmdletBinding()]
    param (
        # Input Object
        [Parameter()]
        [object]
        $InputObject,

        # Prefix for Property Name
        [Parameter()]
        [string] $Prefix,

        # Hidden - Parent - For nested calls
        [Parameter(DontShow)]
        [object] $Parent,

        # Hidden - Array Index - For nested calls
        [Parameter(DontShow)]
        [int] $ArrayIndex,

        # Hidden - Array Count - For nested calls
        [Parameter(DontShow)]
        [int] $ArrayCount,

        # Separator for nested property names.  Default value is '.'.
        [Parameter()]
        [string] $Separator = '.',

        # Properties to ignore/exclude from flattening
        [Parameter()]
        [string[]] $ExcludeProperties,

        # Expand Arrays
        [Parameter()]
        [switch] $ExpandArrays
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

        if($PSBoundParameters.ContainsKey('ExcludeProperties')) {
            foreach ($prop in $ExcludeProperties) {
                $propsExclude.Add($prop, $null)
            }
        }
    }
    
    process {
        Write-Verbose "$('-' * 10) Processing Object:  Level $(0 + $ArrayIndex)"

        foreach ($prop in $InputObject.psobject.Properties) {
            if ($propsExclude.ContainsKey($prop.name)) {
                Write-Verbose "Skipping Excluded Property:  $($prop.name)"
                continue
            }

            Write-Verbose "$(' ' * 4)Name:  $($prop.name)`nType: $($prop.value.getType())"
            $propSeparator = if ($null -ne $Prefix -and $Prefix.Length -gt 0) {$Separator} else {$null}

            # Check for Parent Object
            if ($PSBoundParameters.ContainsKey('Parent')) {
                <# 
                Check if Parent is an Array
                    Need to add option to join array's as text instead of each their own output
                #>
                if ($Parent.isArray) {
                    $padL = $Parent.ArrayCount.toString().Length
                    $propName = '{0}{1}{2}{3}' -f $Parent.Name, $ArrayIndex.ToString().PadLeft($padL, 0).PadLeft($padL + 1,'_'), $propSeparator, $prop.Name
                }
                else {
                    $propName = '{0}{1}{2}' -f $Parent.Name, $propSeparator, $prop.name
                }

                if ($null -ne $Parent.ThisParent) {
                    $thisParent = '{0}{1}{2}' - $Parent.ThisParent, $propSeparator, $Parent.ThisName
                }
                else {
                    $thisParent = $Parent.ThisName
                }
            }
            else {
                $propName = '{0}{1}{2}' -f $Parent.Name, $propSeparator, $prop.name
                $thisParent = $null
            }
        }

        $result = [PSCustomObject]@{
            Name = $propName
            Type = $prop.value.getType()
            TypeNameOfObject = $prop.TypeNameOfObject
            isObject = $prop.value -is [object]
            isPSObject = $prop.value -is [psobject]
            isHash = $prop.value -is [hashtable]
            isArray = $prop.value -is [array]
            ArrayCount = if ($prop.value -is [array]) { $prop.value.count } else { $null }
            ArrayIndex = if ($PSBoundParameters.ContainsKey('ArrayIndex')) {$ArrayIndex} else { $null }
            ThisParent = $thisParent
            ThisName = $prop.Name
            ThisValue = $prop.value
            ArrayJoin = if ($prop.value -is [array]) {($prop.value | ForEach-Object {$PSItem -join ';'}) -join ','} else { $null}
            ArrayToJson = if ($prop.value -is [array]) {$prop.value | ConvertTo-Json -Depth 10 -Compress} else { $null }
        }

        Write-Verbose "Returning Current Result"
        $result

        switch ($prop) {
            {$_.value -is [psobject]} {
                Write-Verbose "isPSObject:  $propName"
                $splatConvertToFlatObject = @{
                    InputObject = $prop.Value
                    Prefix = $propName
                    Parent = $result
                }

                ConvertTo-FlatObject @splatConvertToFlatObject
            }

            {$_.value -is [array]} {
                Write-Verbose "isArray:  $propName - toExpand:  $ExpandArrays"
                if ($ExpandArrays) {
                    $i = 0
                    $padL = $prop.value.count.ToString().Length
                    <#Possible issue if array is just one object#>
                    foreach ($obj in $prop.value) {
                        $i++
                        $splatConvertToFlatObject = @{
                            InputObject = $obj
                            Prefix = '{0}_{1}' -f $propName, $i.toString().PadLeft($padL, 0)
                            Parent = $result
                            ArrayIndex = $i
                        }
    
                        switch ($PSBoundParameters) {
                            {$_.ContainsKey('Verbose')} { $splatConvertToFlatObject.Verbose = $PSBoundParameters.Verbose }
                            {$_.ContainsKey('Separator')} { $splatConvertToFlatObject.Separator = $PSBoundParameters.Separator }
                        }
    
                        ConvertTo-FlatObject @splatConvertToFlatObject
                    }
                }
            }

            Default {}
        }
    }
    
    end {
        
    }
}

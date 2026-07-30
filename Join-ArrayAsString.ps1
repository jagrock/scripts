function Join-ArrayAsString {
    [CmdletBinding()]
    param (
        # Array to Join
        [Parameter()]
        [PSObject[]] $InputObject,

        # Property Value to join   
        [Parameter()]
        [string] $Property,

        # Text to be used as the seperator
        [Parameter()]
        [string] $Seperator = '',

        # Provide a format string to format the text of each object before joining.  Use {0} to represent the current object.
        [Parameter()]
        [string] $FormatString = '{0}',

        # Add a prefix to the output
        [Parameter()]
        [string] $OutputPrefix,

        # Add a suffix to the output
        [Parameter()]
        [string] $OutputSuffix,

        # Add Single or Double quotes around the objects
        [Parameter()]
        [ValidateSet("Single", "Double")] $Quotes
    )
    
    begin {
        
    }
    
    process {
        $tmpArray = [System.Collections.Generic.List[psobject]]::new()

        foreach ($obj in $InputObject) {
            if ($PSBoundParameters.ContainsKey('Quotes')) {
                switch ($Quotes) {
                    'Single' { $tmpQuotes = "'" }
                    'Double' { $tmpQuotes = '"' }
                    Default { $tmpQuotes = '' }
                }
            }

            if ($PSBoundParameters.ContainsKey('Property')) {
                $tmpValue = "$($tmpQuotes)$($FormatString)$($tmpQuotes)" -f $obj.$Property
            } else {
                $tmpValue = "$($tmpQuotes)$($FormatString)$($tmpQuotes)" -f $obj
            }

            $tmpArray.Add($tmpValue)
        }

        $tmpJoin = $tmpArray -join $Seperator

        return $OutputPrefix + $tmpJoin + $OutputSuffix
    }
    
    end {
        
    }
}
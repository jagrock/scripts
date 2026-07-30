function Clear-ExcelTableData {
    [CmdletBinding()]
    param (
        # Table
        [Parameter()]
        [ValidateScript({ $_.GetType().Name -eq 'ExcelTable'})]
        [Object]
        $ExcelTable
    )
    
    begin {
        
    }
    
    process {
        

        
        $xlRange = $ExcelTable.Worksheet.Cells[$ExcelTable.Address].Offset(
            1,
            0, 
            $ExcelTable.Address.Rows - 1, 
            $ExcelTable.Address.Columns
            )

        $ExcelTable.WorkSheet.Cells[$xlRange].Clear()

    }
    
    end {
        
    }
}



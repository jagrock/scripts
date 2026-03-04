function Send-OutlookMailWithSignature {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$To,

        [Parameter()]
        [string]$Subject = "",

        [Parameter()]
        [string]$BodyHtml = "",

        [Parameter()]
        [hashtable]$InlineImages,

        [switch]$DisplayInsteadOfSend
    )

    # ===== Dynamic Signature Parameter =====
    DynamicParam {

        $sigRoot = Join-Path $env:APPDATA "Microsoft\Signatures"

        if (Test-Path $sigRoot) {
            $signatures = Get-ChildItem $sigRoot -Filter *.htm |
                Select-Object -ExpandProperty BaseName
        }
        else {
            $signatures = @()
        }

        $paramAttr = New-Object System.Management.Automation.ParameterAttribute
        $paramAttr.Mandatory = $true

        $attrCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attrCollection.Add($paramAttr)

        if ($signatures.Count -gt 0) {
            $validateSet = New-Object System.Management.Automation.ValidateSetAttribute($signatures)
            $attrCollection.Add($validateSet)
        }

        $runtimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter(
            "SignatureName",
            [string],
            $attrCollection
        )

        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("SignatureName", $runtimeParam)

        return $paramDictionary
    }

    begin {

        $SignatureName = $PSBoundParameters["SignatureName"]

        $sigRoot = Join-Path $env:APPDATA "Microsoft\Signatures"
        $sigHtmlPath = Join-Path $sigRoot "$SignatureName.htm"

        if (!(Test-Path $sigHtmlPath)) {
            throw "Signature not found: $sigHtmlPath"
        }

        $signatureHtml = Get-Content $sigHtmlPath -Raw

        $outlook = New-Object -ComObject Outlook.Application
        $mail = $outlook.CreateItem(0)

        # ===== Process Signature Images =====
        $imgMatches = [regex]::Matches($signatureHtml, 'src="([^"]+)"')

        foreach ($match in $imgMatches) {

            $relativePath = $match.Groups[1].Value
            $fullImagePath = Join-Path $sigRoot $relativePath

            if (Test-Path $fullImagePath) {

                $cid = [guid]::NewGuid().ToString()

                $attachment = $mail.Attachments.Add($fullImagePath)
                $attachment.PropertyAccessor.SetProperty(
                    "http://schemas.microsoft.com/mapi/proptag/0x3712001F",
                    $cid
                )

                $attachment.PropertyAccessor.SetProperty(
                    "http://schemas.microsoft.com/mapi/proptag/0x7FFE000B",
                    $true
                )

                $signatureHtml = $signatureHtml -replace `
                    [regex]::Escape($relativePath),
                    "cid:$cid"
            }
        }

        # ===== Process Additional Inline Images =====
        if ($InlineImages) {
            foreach ($cid in $InlineImages.Keys) {

                $path = $InlineImages[$cid]

                if (!(Test-Path $path)) {
                    throw "Inline image not found: $path"
                }

                $attachment = $mail.Attachments.Add($path)
                $attachment.PropertyAccessor.SetProperty(
                    "http://schemas.microsoft.com/mapi/proptag/0x3712001F",
                    $cid
                )

                $attachment.PropertyAccessor.SetProperty(
                    "http://schemas.microsoft.com/mapi/proptag/0x7FFE000B",
                    $true
                )
            }
        }

        # ===== HTML Conflict Detection =====
        $hasHtmlTag = $BodyHtml -match '(?i)<html'
        $hasBodyTag = $BodyHtml -match '(?i)<body'

        if ($hasHtmlTag) {
            if ($BodyHtml -match '(?i)</body>') {
                $finalHtml = $BodyHtml -replace '(?i)</body>', "<br><br>$signatureHtml</body>"
            }
            else {
                $finalHtml = $BodyHtml + "<br><br>$signatureHtml"
            }
        }
        elseif ($hasBodyTag) {
            $bodyContent = [regex]::Match($BodyHtml, '(?is)<body.*?>(.*?)</body>').Groups[1].Value

            $finalHtml = @"
<html>
<body>
$bodyContent
<br><br>
$signatureHtml
</body>
</html>
"@
        }
        else {
            $finalHtml = @"
<html>
<body style="font-family:Calibri;font-size:11pt;">
$BodyHtml
<br><br>
$signatureHtml
</body>
</html>
"@
        }

        $mail.To = $To
        $mail.Subject = $Subject
        $mail.HTMLBody = $finalHtml

        if ($DisplayInsteadOfSend) {
            $mail.Display()
        }
        else {
            $mail.Send()
        }

        # Cleanup COM
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($mail) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}

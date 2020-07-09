function Format-Policy {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$policy,

        [Parameter(Mandatory = $true)]
        [string]$markdownReport,

        [Parameter(Mandatory = $false)]
        [string]$outFile
    )
    try {
        $filteredPolicy = $policy | Select-Object * -ExcludeProperty id, lastModifiedDateTime, roleScopeTagIds, supportsScopeTags, createdDateTime, version, '*@odata*', assignments
        if ($outFile) {
            $filteredPolicy | ConvertTo-Json -Depth 100 | Out-File -FilePath $outFile -Encoding ascii -Force
        }
        $tmp = @{ }
        $tmp.jsonResult = Format-NullProperties -InputObject $filteredPolicy | ConvertTo-Json -Depth 20
        $tmp.mdResult = Convert-JsonToMarkdown -json ($tmp.jsonResult) -title "### $($filteredPolicy.displayName)"
        $tmp.mdResult | Out-File $markdownReport -Encoding ascii -NoNewline -Append
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}
function Format-Assignment {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Policy,

        [Parameter(Mandatory = $true)]
        [string]$MarkdownReport
    )
    try {

        $assignments = foreach ($p in $Policy.assignments) {
            $a = @{}
            $a.displayName = $p.target.groupId ? $(Get-GroupFromId -id $p.target.groupId -authToken $authToken | Select-Object -ExpandProperty displayName) : '-'
            $a.intent = $p.intent ?? '-'
            $a.mode = $(switch ($p.target.'@odata.type') {
                '#microsoft.graph.exclusionGroupAssignmentTarget' {
                    "Excluded - Group"
                }
                '#microsoft.graph.groupAssignmentTarget' {
                    "Required - Group"
                }
                '#microsoft.graph.allDevicesAssignmentTarget' {
                    "Required - All Devices"
                }
                '#microsoft.graph.allLicensedUsersAssignmentTarget' {
                    "Required - All Users"
                }
                default {
                    $p.target.'@odata.type'
                }
            })
            "| $($a.intent.Substring(0,1).toUpper()+$a.intent.substring(1).tolower()) | $($a.mode) | $($a.displayName) |`n"
        }

        $table = @"

#### Assignments

| Intent    | Mode      | Security Group |
|-----------|-----------|-----------|
$($assignments ?? "| $null | $null | $null |`n")
"@
        $table | Out-File $MarkdownReport -Encoding ascii -NoNewline -Append
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}
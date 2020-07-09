function Format-Assignment {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Policy
    )
    try {

        $assignments = foreach ($p in $Policy.assignments) {
            $a = @{}
            $a.displayName = $p.target.groupId ? $(Get-GroupFromId -id $p.target.groupId -authToken $authToken | Select-Object -ExpandProperty displayName) : $null
            $a.displayName = $a.displayName ?? $null
            $a.intent = $p.intent ?? $null
            if ($null -ne $a.displayName) {
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
            }
            else {
                $a.mode = $null
            }
            "| $($a.intent ? $a.intent.Substring(0,1).toUpper()+$a.intent.Substring(1).toLower() : $null) | $($a.mode) | $($a.displayName) |`n"
        }

        $table = @"

#### Assignments

| Intent    | Mode      | Security Group |
|-----------|-----------|-----------|
$($assignments ?? "| $null | $null | $null |`n")
"@
        $table
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}
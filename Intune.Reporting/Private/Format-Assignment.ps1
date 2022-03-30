function Format-Assignment {
    [OutputType('System.String')]
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Policy
    )
    try {

        $assignments = foreach ($p in $Policy.assignments) {
            $a = [PSCustomObject]@{
                policyName  = $policy.DisplayName
                displayName = $null
                filterName  = $null
                filterType  = $null
                intent      = $null
                mode        = $null
            }
            $a.displayName = $p.target.groupId ? $(Get-GroupFromId -id $p.target.groupId -authToken $authToken | Select-Object -ExpandProperty displayName) : $null
            $a.filterName = $p.target.deviceAndAppManagementAssignmentFilterId ? $(Get-FilterFromId -id $p.target.deviceAndAppManagementAssignmentFilterId -authToken $authToken | Select-Object -ExpandProperty displayName) : $null
            $a.filterType = $p.target.deviceAndAppManagementAssignmentFilterType ?? $null
            $a.displayName = $a.displayName ?? $null
            $a.intent = $p.intent ?? $null
            $a.mode = $(switch ($p.target.'@odata.type') {
                    '#microsoft.graph.exclusionGroupAssignmentTarget' {
                        "Excluded"
                    }
                    '#microsoft.graph.allDevicesAssignmentTarget' {
                        "Included"
                    }
                    '#microsoft.graph.allLicensedUsersAssignmentTarget' {
                        "Included"
                    }
                    '#microsoft.graph.groupAssignmentTarget' {
                        "Included"
                    }
                    default {
                        $p.target.'@odata.type'
                    }
                })

            if ($null -eq $a.displayName) {
                $a.displayName = $(switch ($p.target.'@odata.type') {
                        '#microsoft.graph.allDevicesAssignmentTarget' {
                            "All Devices"
                        }
                        '#microsoft.graph.allLicensedUsersAssignmentTarget' {
                            $a.displayName = "All Users"
                        }
                        default {
                            $p.target.'@odata.type'
                        }
                    })
            }
            $a
        }

        $formatedAssignments = foreach ($a in $assignments) {
            "| $($a.intent ? $a.intent.Substring(0,1).toUpper()+$a.intent.Substring(1).toLower() : $null) | $($a.mode) | $($a.displayName) | $($a.filterName) | $($a.filterType) |`n"
        }

        [string]$table = @"
#### Assignments

| Intent    | Mode      | Security Group | Filter | FilterType |
|-----------|-----------|-----------|-----------|-----------|
$($formatedAssignments ?? "| $null | $null | $null | $null | $null |`n")
"@

        $returnObj = [PSCustomObject]@{
            Table       = $table
            Assignments = $assignments
        }
        return $returnObj
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}
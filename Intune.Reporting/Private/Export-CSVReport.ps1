function Export-CSVReport {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$policies,

        [Parameter(Mandatory = $false)]
        [string]$outFile

    )
    try {
        $assignments = foreach($policy in $policies) {
            foreach ($p in $policy.assignments) {
                $a = [PSCustomObject]@{
                    policyName = $policy.DisplayName
                    displayName = $null
                    filterName = $null
                    filterType = $null
                    intent = $null
                    mode = $null
                }

                $a.displayName = $p.target.groupId ? $(Get-GroupFromId -id $p.target.groupId -authToken $authToken | Select-Object -ExpandProperty displayName) : $null
                $a.filterName = $p.target.deviceAndAppManagementAssignmentFilterId ? $(Get-FilterFromId -id $p.target.deviceAndAppManagementAssignmentFilterId -authToken $authToken | Select-Object -ExpandProperty displayName) : $null
                $a.filterType = $p.target.deviceAndAppManagementAssignmentFilterType ?? $null
                $a.displayName = $a.displayName ?? $null
                $a.intent = $p.intent ?? $null
                if ($null -eq $a.displayName) {
                    $a.mode = $(switch ($p.target.'@odata.type') {
                            '#microsoft.graph.exclusionGroupAssignmentTarget' {
                                "Excluded"
                            }
                            '#microsoft.graph.groupAssignmentTarget' {
                                "Required"
                            }
                            '#microsoft.graph.allDevicesAssignmentTarget' {
                                $null
                            }
                            '#microsoft.graph.allLicensedUsersAssignmentTarget' {
                                $null
                            }
                            default {
                                $p.target.'@odata.type'
                            }
                        })
                        $a.displayName = $(switch ($p.target.'@odata.type') {
                            '#microsoft.graph.allDevicesAssignmentTarget' {
                                "All Devices"
                            }
                            '#microsoft.graph.allLicensedUsersAssignmentTarget' {
                                "All Users"
                            }
                            default {
                                $null
                            }
                        })
                    
                }
                else {
                    $a.mode = $null
                }
                $a.intent = $a.intent ? $a.intent.Substring(0,1).toUpper()+$a.intent.Substring(1).toLower() : $null
                $a
            }
        }

        $assignments | Export-CSV -Path $outFile -Force

     }
    catch {
        $_
        Write-Warning $_.Exception.Message
    }
}
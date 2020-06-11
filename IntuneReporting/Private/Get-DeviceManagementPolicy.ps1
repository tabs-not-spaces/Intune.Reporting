Function Get-DeviceManagementPolicy {
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        $authToken,

        [Parameter(Mandatory)]
        [ValidateSet('ADMX', 'AutoPilot', 'Compliance', 'Configuration', 'EnrollmentStatus', 'Script')]
        [string]$managementType

    )
    $itemType = "$managementType Policies"
    $filter = $null
    switch ($managementType) {
        "ADMX" {
            $graphEndpoint = "deviceManagement/groupPolicyConfigurations"
            break

        }
        "AutoPilot" {
            $graphEndpoint = "deviceManagement/windowsAutopilotDeploymentProfiles"
            break
        }
        "Compliance" {
            $graphEndpoint = "deviceManagement/deviceCompliancePolicies"
            break
        }
        "Configuration" {
            $graphEndpoint = "deviceManagement/deviceConfigurations"
            break
        }
        "EnrollmentStatus" {
            $graphEndpoint = "deviceManagement/deviceEnrollmentConfigurations"
            $filter = "?`$filter=isOf('microsoft.graph.windows10EnrollmentCompletionPageConfiguration')"
            break
        }
        "Script" {
            $graphEndpoint = "deviceManagement/deviceManagementScripts"
            $itemType = "PowerShell Scripts"
            break
        }
    }
    $graphApiVersion = "Beta"
    Write-Verbose "Resource: $graphEndpoint"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
    try {
        $response = (Invoke-RestMethod -Method Get -Uri "$uri$filter" -Headers $authToken -ContentType "application/json").value | ForEach-Object {
            Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)/$($_.id)?`$expand=Assignments" -Headers $authToken -ContentType "application/json"
        }
        Write-Host "$itemType`: $($response.count) items found."
        return $response
    }
    catch {
        $ex = $_.Exception
        Write-Warning $ex
        break
    }
}
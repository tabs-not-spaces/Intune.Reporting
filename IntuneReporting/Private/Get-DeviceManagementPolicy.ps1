Function Get-DeviceManagementPolicy {
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $authToken,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ADMX', 'AutoPilot', 'Compliance', 'Configuration','EndpointSecurity', 'EnrollmentStatus', 'Script')]
        [string]$managementType

    )
    $itemType = "$managementType Policies"
    $filter = $null
    $expand = '?$expand=Assignments'
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
        "EndpointSecurity" {
            $graphEndpoint = "deviceManagement/intents"
            $expand = '?$expand=Assignments,Settings($select=id,definitionId,valueJson)'
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
            Invoke-RestMethod -Method Get -Uri "$uri/$($_.id)$expand" -Headers $authToken -ContentType "application/json"
        }
        Write-Host "$itemType`: " -NoNewline -ForegroundColor Cyan
        write-host "$($response.count) items found." -ForegroundColor Green
        return $response
    }
    catch {
        $ex = $_.Exception
        Write-Warning $ex
        break
    }
}
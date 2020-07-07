Function Get-DeviceManagementPolicy {
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $AuthToken,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ADMX', 'AutoPilot', 'Compliance', 'Configuration','EndpointSecurity', 'EnrollmentStatus', 'Script')]
        [string]$ManagementType

    )
    $itemType = "$ManagementType Policies"
    $filter = $null
    $expand = '?$expand=Assignments'
    switch ($ManagementType) {
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
    Write-Verbose "`nResource: $graphEndpoint"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
    try {
        $response = (Invoke-RestMethod -Method Get -Uri "$uri$filter" -Headers $AuthToken -ContentType "application/json").value | ForEach-Object {
            Invoke-RestMethod -Method Get -Uri "$uri/$($_.id)$expand" -Headers $AuthToken -ContentType "application/json"
        }
        Write-Host "$itemType`: " -NoNewline -ForegroundColor Cyan
        write-host "$($response.count) $(($response.count -eq 1) ? "item" : "items") found." -ForegroundColor Green
        return $response
    }
    catch {
        $ex = $_.Exception
        Write-Warning $ex
        break
    }
}
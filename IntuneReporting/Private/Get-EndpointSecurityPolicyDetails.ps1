function Get-EndpointSecurityPolicyDetails {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)]
        $AuthToken,

        [parameter(Mandatory=$true)]
        [object]$ESPolicies
    )
    try {
        $graphEndpoint = "deviceManagement/templates"
        $graphApiVersion = "Beta"
        Write-Verbose "`nResource: $graphEndpoint"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
        foreach ($e in $ESPolicies) {
            $sd = (Invoke-RestMethod -Method Get -Uri "$uri/$($e.templateId)/categories?`$expand=settingDefinitions" -Headers $AuthToken -ContentType "application/json").value
            foreach ($s in $e.settings) {
                $s | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value ($sd.settingDefinitions | Where-Object {$_.id -eq $s.definitionId} | Select-Object -Unique).DisplayName

            }
        }
    }
    catch {
        $_
    }
}
function Get-MobileAppConfiguration {
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $AuthToken,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Office365', 'Win32')]
        [string]$MobileAppType

    )
    switch ($MobileAppType) {
        "Office365" {
            $odata = "microsoft.graph.officeSuiteApp"
            break
        }
        "Win32" {
            $odata = "microsoft.graph.win32LobApp"
            break
        }
    }
    $graphApiVersion = "Beta"
    $graphEndpoint = "deviceappmanagement/mobileapps?`$filter=isOf('$odata')"
    Write-Verbose "`nResource: $graphEndpoint"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
    try {
        $apps = Invoke-RestMethod -Method Get -Uri $uri -ContentType 'Application/Json' -Headers $AuthToken | Select-Object -ExpandProperty value
        Write-Host "$MobileAppType applications: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($apps.count) $(($apps.count -eq 1) ? "item" : "items") found." -ForegroundColor Green
        $result = foreach ($a in $apps) {
            $ur = "https://graph.microsoft.com/beta/deviceappmanagement/mobileapps/$($a.id)?`$expand=Assignments"
            Invoke-RestMethod -Method Get -Uri $ur -Headers $AuthToken | Select-Object * -exclude LargeIcon
        }
        $result
    }
    catch {
        Write-Warning $_.Exception
    }
}
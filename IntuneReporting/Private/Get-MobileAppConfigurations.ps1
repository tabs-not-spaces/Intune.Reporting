function Get-MobileAppConfigurations {
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        $authToken = $authToken,

        [Parameter(Mandatory)]
        [ValidateSet('office365', 'win32')]
        [string]$mobileAppType

    )
    switch ($mobileAppType) {
        "office365" {
            $odata = "microsoft.graph.officeSuiteApp"
            break
        }
        "win32" {
            $odata = "microsoft.graph.win32LobApp"
            break
        }
    }
    $graphApiVersion = "Beta"
    $graphEndpoint = "deviceappmanagement/mobileapps?`$filter=isOf('$odata')"
    Write-Verbose "`nResource: $graphEndpoint"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
    try {
        $apps = Invoke-RestMethod -Method Get -Uri $uri -ContentType 'Application/Json' -Headers $authToken | Select-Object -ExpandProperty value
        Write-Host "$mobileAppType applications: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($apps.count) items found." -ForegroundColor Green
        $result = foreach ($a in $apps) {
            $ur = "https://graph.microsoft.com/beta/deviceappmanagement/mobileapps/$($a.id)?`$expand=Assignments"
            Invoke-RestMethod -Method Get -Uri $ur -Headers $authToken | Select-Object * -exclude LargeIcon
        }
        $result
    }
    catch {
        Write-Warning $_.Exception
    }
}
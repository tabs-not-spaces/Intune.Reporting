function Get-CategoryFromId {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        $id,

        [parameter(Mandatory = $true)]
        $authToken
    )
    try {
        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppCategories/$($id)?`$select=id,displayName"
        $res = Invoke-RestMethod -Method Get -Uri $uri -ContentType 'Application/Json' -Headers $authToken
        return $res
    }
    catch {
        return $null
    }
}
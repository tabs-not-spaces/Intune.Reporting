function Get-GroupFromId {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        $id,

        [parameter(Mandatory = $true)]
        $authToken
    )
    $uri = "https://graph.microsoft.com/beta/groups/$($id)?`$select=id,displayName"
    $res = Invoke-RestMethod -Method Get -Uri $uri -ContentType 'Application/Json' -Headers $authToken
    return $res
}
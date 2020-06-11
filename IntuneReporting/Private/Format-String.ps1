function Format-String {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$inputString
    )
    return ($inputString -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"  -replace '\[', '(' -replace '\]', ')' )
}
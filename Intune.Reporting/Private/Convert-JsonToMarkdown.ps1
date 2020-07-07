function Convert-JsonToMarkdown {
    param(
        [parameter(Mandatory = $true)]
        [string]$Json,

        [parameter(Mandatory = $false)]
        [string]$Title
    )
    ## need this installed
    #install-module newtonsoft.json -Scope AllUsers
    #import-module newtonsoft.json
    $a = ConvertFrom-JsonNewtonsoft $Json
    $tableContent = Get-DataFromOrderedDic $a
    $table = @"

$Title

| Property  | Value     |
|-----------|-----------|
$tableContent
"@
    return $table
}
function Convert-JsonToMarkdown {
    param(
        [parameter(Mandatory = $true)]
        [string]$Json,

        [parameter(Mandatory = $false)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [switch]$onlyListPolicyTitle
    )
    if ($onlyListPolicyTitle) {
        $table = @"

$Title
"@
        return $Title
    }
    else {
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
    
}
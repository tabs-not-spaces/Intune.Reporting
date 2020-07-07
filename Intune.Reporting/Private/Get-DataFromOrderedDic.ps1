function Get-DataFromOrderedDic {
    param(
        [parameter(Mandatory = $true)]
        $OrderedDic,

        [parameter(Mandatory = $true)]
        $Parent
    )
    $a = $OrderedDic
    $vars = $a.Keys
    foreach ($x in $vars) {
        if (($a.$x | Get-Member -ErrorAction SilentlyContinue).TypeName -eq "System.Collections.Specialized.OrderedDictionary") {
            foreach ($y in $a.$x) {
                if ($Parent) {
                    Get-DataFromOrderedDic $y "$($Parent).$x"
                }
                else {
                    Get-DataFromOrderedDic $y $x
                }
            }
        }
        else {
            if ($Parent) {
                if ($($a.$x) -notin $null, " ", "notConfigured") {
                    "| $($Parent).$($x) | $($a.$x) |`n"
                }
            }
            else {
                if ($($a.$x) -notin $null, " ", "notConfigured") {
                    "| $($x) | $($a.$x) |`n"
                }
            }
        }
    }
}
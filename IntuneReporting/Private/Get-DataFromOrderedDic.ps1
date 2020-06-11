function Get-DataFromOrderedDic {
    param(
        $orderedDic,
        $parent
    )
    $a = $orderedDic
    $vars = $a.Keys
    foreach ($x in $vars) {
        if (($a.$x | Get-Member -ErrorAction SilentlyContinue).TypeName -eq "System.Collections.Specialized.OrderedDictionary") {
            foreach ($y in $a.$x) {
                if ($parent) {
                    Get-DataFromOrderedDic $y "$($parent).$x"
                }
                else {
                    Get-DataFromOrderedDic $y $x
                }
            }
        }
        else {
            if ($parent) {
                if ($($a.$x) -notin $null, " ", "notConfigured") {
                    "| $($parent).$($x) | $($a.$x) |`n"
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
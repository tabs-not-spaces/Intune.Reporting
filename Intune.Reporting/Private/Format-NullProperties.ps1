function Format-NullProperties {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [psobject] $InputObject
    )
    process {
        $obj = [pscustomobject]::new()
        foreach ($prop in $InputObject.psobject.properties) {
            if (($($InputObject.$($prop.Name).length) -ne 0)) {
                if ($($InputObject.$($prop.Name) -ne "notConfigured")) {
                    Add-Member -InputObject $obj -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
                }
            }
        }
        $obj.pstypenames.Insert(0, 'NonNull.' + $InputObject.GetType().FullName)
        return $obj
    }
}
---
external help file: IntuneReporting-help.xml
Module Name: Intune.Reporting
online version:
schema: 2.0.0
---

# Build-IntuneConfigReport

## SYNOPSIS
Capture and document all Intune configuration items, policies and applications.

## SYNTAX

```
Build-IntuneConfigReport [-Tenant] <Uri> [-OutputFolder] <String> [<CommonParameters>]
```

## DESCRIPTION
Single function that will capture and document all configuration items, policies and applications within your Intune tenant.

## EXAMPLES

### Example 1
```powershell
PS C:\> Build-IntuneConfigReport -Tenant 'ba6eab59-a57c-4b92-ac71-6c3342cdc6c8' -outputFolder 'C:\reports'
```

This example will authenticate to the tenant 'ba6eab59-a57c-4b92-ac71-6c3342cdc6c8' and generate content in a folder named 'ba6eab59-a57c-4b92-ac71-6c3342cdc6c8' within C:\reports

### Example 1
```powershell
PS C:\> Build-IntuneConfigReport -Tenant 'Powers-Hell.com' -outputFolder 'C:\reports'
```

This example will authenticate to the tenant 'Powers-Hell.com' and generate content in a folder named 'Powers-Hell.com' within C:\reports

## PARAMETERS

### -OutputFolder
The root folder where you want to store the output of the command. A sub folder will be created with the name provided from the tenant parameter.

```yaml
Type: String / FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tenant
The address of the Azure tenant you want to query - either the domain or the Azure TenantId will work.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

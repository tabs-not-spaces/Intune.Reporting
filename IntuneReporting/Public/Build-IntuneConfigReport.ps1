function Build-IntuneConfigReport {
    [cmdletbinding()]
    param (
        [Parameter(mandatory = $true)]
        [System.Uri]$TenantId,

        [Parameter(mandatory = $true)]
        [System.IO.FileInfo]$OutputFolder
    )
    try {
        #region authentication
        if (!($PSVersionTable.PSEdition -eq 'core')) {
            throw "Needs to be run in PWSH 7."
        }
        $auth = Get-MsalToken -ClientId $script:applicationId -TenantId $TenantId
        $authToken = @{
            'Content-Type'  = 'application/json'
            'Authorization' = $auth.CreateAuthorizationHeader()
            'ExpiresOn'     = $($auth.ExpiresOn.LocalDateTime)
        }
        #endregion
        #region configuration
        $outputPath = "$outputFolder\$tenantId"
        $paths = @{
            admx              = "$outputPath\admx"
            apps              = "$outputPath\apps"
            autopilotPath     = "$outputPath\autopilot"
            compliancePath    = "$outputPath\compliance-policies"
            configurationPath = "$outputPath\config-profiles"
            endpointSecurity  = "$outputPath\endpoint-security-policies"
            esp               = "$outputPath\esp"
            o365              = "$outputPath\o365"
            scriptPath        = "$outputPath\scripts"
        }
        $markdownReport = "$outputPath\$tenantId`_report.md"
        #endregion
        #region prepare folder structure
        foreach ($p in $paths.values) {
            if (!(Test-Path $p)) {
                New-Item -Path $p -ItemType Directory -Force | Out-Null
            }
        }
        if (!(Test-Path $markdownReport)) {
            New-Item -Path $markdownReport -ItemType File -Force | Out-Null
        }
        else {
            Remove-Item -Path $markdownReport -Force | Out-Null
            New-Item -Path $markdownReport -ItemType File -Force | Out-Null
        }
        #endregion
        #region Generate Title of report
        #endregion
        #region Grab the endpoint data
        $admxConfiguration = Get-DeviceManagementPolicy -authToken $authToken -managementType ADMX | Select-Object * -ExcludeProperty value
        $autoPilot = Get-DeviceManagementPolicy -authToken $authToken -managementType AutoPilot | Select-Object * -ExcludeProperty value
        $deviceCompliance = Get-DeviceManagementPolicy -authToken $authToken -managementType Compliance | Select-Object * -ExcludeProperty value
        $deviceConfiguration = Get-DeviceManagementPolicy -authToken $authToken -managementType Configuration | Select-Object * -ExcludeProperty value
        $endpointSecurityPolicy = Get-DeviceManagementPolicy -authToken $authToken -managementType EndpointSecurity | Select-Object * -ExcludeProperty value
        $enrollmentStatus = Get-DeviceManagementPolicy -authToken $authToken -managementType EnrollmentStatus | Select-Object * -ExcludeProperty value
        $scripts = Get-DeviceManagementPolicy -authToken $authToken -managementType Script | Select-Object * -ExcludeProperty value
        $office365 = Get-MobileAppConfigurations -authToken $authToken -mobileAppType office365
        $win32Apps = Get-MobileAppConfigurations -authToken $authToken -mobileAppType win32
        #endregion
        #region ADMX
        if ($admxConfiguration) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " ADMX Policies                " -NoNewline -ForegroundColor Green
            "## ADMX Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($gpc in $admxConfiguration) {
                "`n### $($gpc.displayName)`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                $folderName = Format-String -inputString $gpc.displayName
                New-Item "$($paths.admx)\$folderName" -ItemType Directory -Force | Out-Null
                $gpcDefinitionValues = Get-GroupPolicyConfigurationsDefinitionValues -GroupPolicyConfigurationID $gpc.id
                foreach ($v in $gpcDefinitionValues) {
                    $definitionValuedefinition = Get-GroupPolicyConfigurationsDefinitionValuesdefinition -GroupPolicyConfigurationID $gpc.id -GroupPolicyConfigurationsDefinitionValueID $v.id
                    #$definitionValuedefinitionID = $definitionValuedefinition.id
                    $definitionValuedefinitionDisplayName = $definitionValuedefinition.displayName
                    #$groupPolicyDefinitionsPresentations = Get-GroupPolicyDefinitionsPresentations -groupPolicyDefinitionsID $gpc.id -GroupPolicyConfigurationsDefinitionValueID $v.id
                    $definitionValuePresentationValues = Get-GroupPolicyConfigurationsDefinitionValuesPresentationValues -GroupPolicyConfigurationID $gpc.id -GroupPolicyConfigurationsDefinitionValueID $v.id
                    $outdef = [PSCustomObject]@{
                        enabled = $($v.enabled.tostring().tolower())
                    }
                    if ($definitionValuePresentationValues.count -gt 1) {
                        $presvalues = foreach ($pres in $definitionValuePresentationValues) {
                            $pres | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, '*@odata*'
                        }
                        $outdef | Add-Member -MemberType NoteProperty -Name "presentationValues" -Value $presvalues
                    }
                    $filename = Format-String -inputString "$($DefinitionValuedefinition.categoryPath)-$definitionValuedefinitionDisplayName"
                    $outdef | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($paths.admx)\$($folderName)\$filename.json" -Encoding ascii
                    $tmp = @{ }
                    $tmp.jsonResult = Remove-NullProperties -InputObject $outdef | ConvertTo-Json -Depth 20
                    $tmp.mdResult = Convert-JsonToMarkdown -json ($tmp.jsonResult) -title "`n##### $($filename -replace '_', ' ')"
                    $tmp.mdResult | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                }
                Format-Assignment -policy $gpc -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region AutoPilot
        if ($autoPilot) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " AutoPilot Policies           " -NoNewline -ForegroundColor Green
            "`n## AutoPilot Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($a in $autoPilot) {
                Format-Policy -policy $a -markdownReport $markdownReport -outFile "$($paths.autopilotPath)\$(Format-String -inputString $a.displayName)`.json"
                Format-Assignment -policy $a -markdownReport $markdownReport

            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Compliance
        if ($deviceCompliance) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Device Compliance Policies   " -NoNewline -ForegroundColor Green
            "`n## Device Compliance Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($d in $deviceCompliance) {
                Format-Policy -policy $d -markdownReport $markdownReport -outFile "$($paths.compliancePath)\$(Format-String -inputString $d.displayName)`.json"
                Format-Assignment -policy $d -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Configuration
        if ($deviceConfiguration) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Device Configuration Policies" -NoNewline -ForegroundColor Green
            "`n## Device Configuration Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($d in $deviceConfiguration) {
                $displayName = $null
                $displayName = $d.displayName -replace '\[', '(' -replace '\]', ')'
                Format-Policy -policy $d -markdownReport $markdownReport -outFile "$($paths.configurationPath)\$(Format-String -inputString $d.displayName)`.json"
                Format-Assignment -policy $d -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Endpoint Security Policies
        if ($endpointSecurityPolicy) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Endpoint Security Policies   " -NoNewline -ForegroundColor Green
            "`n## Endpoint Security Policy`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($e in $endpointSecurityPolicy) {
                "`n### $($e.displayName)`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                $folderName = Format-String -inputString $e.displayName
                New-Item "$($paths.endpointSecurity)\$folderName" -ItemType Directory -Force | Out-Null
                # store template
                $e | Select-Object templateId, displayName, description | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($paths.endpointSecurity)\$($folderName)\template.json" -Encoding ascii
                #store intents
                $intents = $($e.settings | Select-Object '*@odata*', definitionId, ValueJson | ConvertTo-Json -Depth 10)
                @{
                    "settings" = $intents
                } | ConvertTo-Json | Out-File -FilePath "$($paths.endpointSecurity)\$($folderName)\intent.json" -Encoding ascii
                #expand setting values
                Get-EndpointSecurityPolicyDetails -AuthToken $authToken -ESPolicies $e
                foreach ($s in $e.settings) {
                    if (!($s.valueJson -eq '"notConfigured"' -or $s.valueJson -eq 'null')) {
                        Write-Host "$($s.DisplayName): $($s.valueJson)"
                        $tmp = @{}
                        if ((($s.valueJson | ConvertFrom-Json).psobject.members | Where-Object { $_.membertype -eq "NoteProperty" }).count -eq 0) {
                            $tmp.jsonResult = $s | Select-Object @{ Name = $s.DisplayName; Expression = { $_.valueJson | ConvertFrom-Json } } | ConvertTo-Json -Depth 10
                        }
                        else {
                            $tmp.jsonResult = $s | Select-Object @{ Name = 'Value'; Expression = { $_.valueJson | ConvertFrom-Json } } | ConvertTo-Json -Depth 10
                        }
                        $tmp.mdResult = (Convert-JsonToMarkdown -json ($tmp.jsonResult) -title "#### $($s.DisplayName)") -replace 'Value\.'
                        $tmp.mdResult | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                    }
                    else {
                        Write-Warning "$($s.DisplayName): $($s.valueJson)"
                    }
                }
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Enrollment Status Page
        if ($enrollmentStatus) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Enrollment Status Policies   " -NoNewline -ForegroundColor Green
            "`n## Enrollment Status Policy`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($e in $enrollmentStatus) {
                Format-Policy -policy $e -markdownReport $markdownReport -outFile "$($paths.esp)\$(Format-String -inputString $e.displayName)`.json"
                Format-Assignment -policy $e -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Scripts
        if ($scripts) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " PowerShell Scripts           " -NoNewline -ForegroundColor Green
            "`n## PowerShell Scripts`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($s in $scripts) {
                $displayName = $null
                $displayName = Format-String -inputString $s.displayName
                #store the script contents locally
                New-Item "$($paths.scriptPath)\$displayName" -ItemType Directory -Force | Out-Null
                [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($s.scriptContent)")) |
                Out-File -FilePath "$($paths.scriptPath)\$displayName\$displayName`.ps1" -Encoding ascii -Force

                $fpParam = @{
                    policy         = $($s | Select-Object displayName, description, runAsAccount, enforceSignatureCheck, fileName, runAs32Bit, '*@odata*', assignments)
                    markdownReport = $markdownReport
                    outFile        = "$($paths.scriptPath)\$displayName\$displayName`.json"
                }
                Format-Policy @fpParam
                Format-Assignment -policy $s -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Office 365 Applications
        if ($office365) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Office 365                   " -NoNewline -ForegroundColor Green
            "`n## Office 365 Configuration`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($o in $office365) {
                Format-Policy -policy $o -markdownReport $markdownReport -outFile "$($paths.o365)\$(Format-String -inputString $o.displayName)`.json"
                Format-Assignment -policy $o -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region win32 Applications
        if ($win32Apps) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Win32 Applications           " -NoNewline -ForegroundColor Green
            "`n## Win32 Applications`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($a in $win32Apps) {
                Format-Policy -policy $a -markdownReport $markdownReport -outFile "$($paths.apps)\$(Format-String -inputString $a.displayName)`.json"
                Format-Assignment -policy $a -markdownReport $markdownReport
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    finally {
        if (Test-Path $markdownReport -ErrorAction SilentlyContinue) {
            Write-Host "`rReport Generated:" -NoNewline -ForegroundColor Green
            Write-Host " $markdownReport`n" -ForegroundColor Yellow
        }
    }
}
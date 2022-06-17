function Build-IntuneConfigReport {
    [cmdletbinding()]
    param (
        [Parameter(mandatory = $true)]
        [System.Uri]$Tenant,

        [Parameter(mandatory = $true)]
        [System.IO.FileInfo]$OutputFolder,

        [Parameter(mandatory = $false)]
        [ValidateSet('admx','autopilot','deviceCompliance','deviceConfiguration','endpointSecurityPolicy','enrollmentStatus','featureUpdate','scripts','office365','proactiveRemediation','win32Apps')]
        [string[]]$Filter
    )
    try {
        #region authentication
        if (!($PSVersionTable.PSEdition -eq 'core')) {
            throw "Needs to be run in PWSH 7."
        }
        if ($null -eq $script:auth) {
            $script:auth = Get-MsalToken -ClientId $script:applicationId -Tenant $Tenant -DeviceCode
        }
        $authToken = @{
            'Content-Type'  = 'application/json'
            'Authorization' = $script:auth.CreateAuthorizationHeader()
            'ExpiresOn'     = $($script:auth.ExpiresOn.LocalDateTime)
        }
        #endregion
        #region Grab the endpoint data
        if ($null -eq $Filter) {
            [string[]]$Filter = 'all'
        }
        Write-Host "Grabbing configuration.. ☕" -ForegroundColor Yellow
        $config = @{
            admxConfiguration      = $Filter -match "all|admx" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType ADMX) : $null
            autopilot              = $Filter -match "all|autopilot" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType AutoPilot) : $null
            deviceCompliance       = $Filter -match "all|deviceCompliance" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType Compliance) : $null
            deviceConfiguration    = $Filter -match "all|deviceConfiguration" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType Configuration) : $null
            endpointSecurityPolicy = $Filter -match "all|endpointSecurityPolicy" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType EndpointSecurity) : $null
            enrollmentStatus       = $Filter -match "all|enrollmentStatus" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType EnrollmentStatus) : $null
            featureUpdate          = $Filter -match "all|featureUpdate" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType FeatureUpdate) : $null
            scripts                = $Filter -match "all|scripts" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType Script) : $null
            office365              = $Filter -match "all|office365" ? (Get-MobileAppConfigurations -AuthToken $authToken -MobileAppType Office365) : $null
            proactiveRemediation     = $Filter -match "all|proactiveRemediation" ? (Get-DeviceManagementPolicy -AuthToken $authToken -ManagementType ProactiveRemediation) : $null
            win32Apps              = $Filter -match "all|win32Apps" ? (Get-MobileAppConfigurations -AuthToken $authToken -MobileAppType Win32) : $null
        }
        #endregion
        #region configuration
        $outputPath = (Join-Path -Path $OutputFolder -ChildPath $Tenant).toString()
        $paths = @{
            admx              = (($config.admxConfiguration) ? "$outputPath\admx" : $null)
            apps              = (($config.win32Apps) ? "$outputPath\apps" : $null)
            autopilotPath     = (($config.autoPilot) ? "$outputPath\autopilot" : $null)
            compliancePath    = (($config.deviceCompliance) ? "$outputPath\compliance-policies" : $null)
            configurationPath = (($config.deviceConfiguration) ? "$outputPath\config-profiles" : $null)
            endpointSecurity  = (($config.endpointSecurityPolicy) ? "$outputPath\endpoint-security-policies" : $null)
            esp               = (($config.enrollmentStatus) ? "$outputPath\esp" : $null)
            fu                = (($config.featureUpdate) ? "$outputPath\feature-update" : $null)
            o365              = (($config.office365) ? "$outputPath\o365" : $null)
            prScripts         = (($config.proactiveRemediation) ? "$outputPath\proactive-remediation-scripts" : $null)
            scriptPath        = (($config.scripts) ? "$outputPath\scripts" : $null)
        }
        $markdownReport = "$outputPath\$Tenant`_report.md"
        #endregion
        #region prepare folder structure
        foreach ($p in ($paths.values | Where-Object { $null -ne $_ })) {
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
        #region ADMX
        if ($config.admxConfiguration) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " ADMX Policies                " -NoNewline -ForegroundColor Green
            "## ADMX Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($gpc in $config.admxConfiguration) {
                "`n### $($gpc.displayName)`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                $folderName = Format-String -inputString $gpc.displayName
                New-Item "$($paths.admx)\$folderName" -ItemType Directory -Force | Out-Null
                $gpcDefinitionValues = Get-GroupPolicyConfigurationsDefinitionValues -GroupPolicyConfigurationID $gpc.id
                foreach ($v in $gpcDefinitionValues) {
                    $definitionValuedefinition = Get-GroupPolicyConfigurationsDefinitionValuesdefinition -GroupPolicyConfigurationID $gpc.id -GroupPolicyConfigurationsDefinitionValueID $v.id
                    $definitionValuedefinitionDisplayName = $definitionValuedefinition.displayName
                    $definitionValuePresentationValues = Get-GroupPolicyConfigurationsDefinitionValuesPresentationValues -GroupPolicyConfigurationID $gpc.id -GroupPolicyConfigurationsDefinitionValueID $v.id
                    $outdef = [PSCustomObject]@{
                        enabled = $($v.enabled.tostring().tolower())
                    }
                    if ($definitionValuePresentationValues.values.count -gt 1) {
                        $presvalues = foreach ($pres in $definitionValuePresentationValues.values) {
                            $pres | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, '*@odata*'
                        }
                        $outdef | Add-Member -MemberType NoteProperty -Name "presentationValues" -Value $presvalues
                    }
                    $filename = Format-String -inputString "$($DefinitionValuedefinition.categoryPath)-$definitionValuedefinitionDisplayName"
                    $outdef | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($paths.admx)\$($folderName)\$filename.json" -Encoding ascii
                    $tmp = @{ }
                    $tmp.jsonResult = Format-NullProperties -InputObject $outdef | ConvertTo-Json -Depth 20
                    $tmp.mdResult = (Convert-JsonToMarkdown -json ($tmp.jsonResult) -title "`n##### $($filename -replace '_', ' ')" ) -replace 'presentationValues.',''
                    $tmp.mdResult | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                }
                Format-Assignment -policy $gpc | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region AutoPilot
        if ($config.autoPilot) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " AutoPilot Policies           " -NoNewline -ForegroundColor Green
            "`n## AutoPilot Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($a in $config.autoPilot) {
                Format-Policy -policy $a -markdownReport $markdownReport -outFile "$($paths.autopilotPath)\$(Format-String -inputString $a.displayName)`.json"
                Format-Assignment -policy $a | Out-File $markdownReport -Encoding ascii -NoNewline -Append

            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Compliance
        if ($config.deviceCompliance) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Device Compliance Policies   " -NoNewline -ForegroundColor Green
            "`n## Device Compliance Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($d in $config.deviceCompliance) {
                Format-Policy -policy $d -markdownReport $markdownReport -outFile "$($paths.compliancePath)\$(Format-String -inputString $d.displayName)`.json"
                Format-Assignment -policy $d | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Configuration
        if ($config.deviceConfiguration) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Device Configuration Policies" -NoNewline -ForegroundColor Green
            "`n## Device Configuration Policies`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($d in $config.deviceConfiguration) {
                Format-Policy -policy $d -markdownReport $markdownReport -outFile "$($paths.configurationPath)\$(Format-String -inputString $d.displayName)`.json"
                Format-Assignment -policy $d | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Endpoint Security Policies
        if ($config.endpointSecurityPolicy) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Endpoint Security Policies   " -NoNewline -ForegroundColor Green
            "`n## Endpoint Security Policy`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($e in $config.endpointSecurityPolicy) {
                "`n### $($e.displayName)`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                $folderName = Format-String -inputString $e.displayName
                New-Item "$($paths.endpointSecurity)\$folderName" -ItemType Directory -Force | Out-Null
                # store template
                $e | Select-Object templateId, displayName, description | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($paths.endpointSecurity)\$folderName\template.json" -Encoding ascii
                #store intents
                $intents = $($e.settings | Select-Object '*@odata*', definitionId, ValueJson | ConvertTo-Json -Depth 10)
                @{
                    "settings" = $intents
                } | ConvertTo-Json | Out-File -FilePath "$($paths.endpointSecurity)\$folderName\intent.json" -Encoding ascii
                #expand setting values
                Get-EndpointSecurityPolicyDetails -AuthToken $authToken -ESPolicies $e
                foreach ($s in $e.settings) {
                    if (!($s.valueJson -eq '"notConfigured"' -or $s.valueJson -eq 'null')) {
                        Write-Verbose "$($s.DisplayName): $($s.valueJson)"
                        $tmp = @{}
                        if ((($s.valueJson | ConvertFrom-Json).psobject.members | Where-Object { $_.membertype -eq "NoteProperty" }).count -eq 0) {
                            $tmp.jsonResult = $s | Select-Object @{ Name = $s.DisplayName; Expression = { $_.valueJson | ConvertFrom-Json } } | ConvertTo-Json -Depth 10
                        }
                        else {
                            $tmp.jsonResult = $s | Select-Object @{ Name = 'Value'; Expression = { $_.valueJson | ConvertFrom-Json } } | ConvertTo-Json -Depth 10
                        }
                        $tmp.mdResult = (Convert-JsonToMarkdown -json $tmp.jsonResult -title "#### $($s.DisplayName)") -replace 'Value\.'
                        $tmp.mdResult | Out-File $markdownReport -Encoding ascii -NoNewline -Append
                    }
                    else {
                        Write-Verbose "$($s.DisplayName): $($s.valueJson)"
                    }
                }
                Format-Assignment -policy $e | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Enrollment Status Page
        if ($config.enrollmentStatus) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Enrollment Status Policies   " -NoNewline -ForegroundColor Green
            "`n## Enrollment Status Policy`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($e in $config.enrollmentStatus) {
                Format-Policy -policy $e -markdownReport $markdownReport -outFile "$($paths.esp)\$(Format-String -inputString $e.displayName)`.json"
                Format-Assignment -policy $e | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Feature Update
        if ($config.featureUpdate) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Feature Updates   " -NoNewline -ForegroundColor Green
            "`n## Feature Update Policy`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($f in $config.featureUpdate) {
                Format-Policy -policy $f -markdownReport $markdownReport -outFile "$($paths.fu)\$(Format-String -inputString $f.displayName)`.json"
                Format-Assignment -policy $f | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Scripts
        if ($config.scripts) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " PowerShell Scripts           " -NoNewline -ForegroundColor Green
            "`n## PowerShell Scripts`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($s in $config.scripts) {
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
                Format-Assignment -policy $s | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Office 365 Applications
        if ($config.office365) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Office 365                   " -NoNewline -ForegroundColor Green
            "`n## Office 365 Configuration`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($o in $config.office365) {
                Format-Policy -policy $o -markdownReport $markdownReport -outFile "$($paths.o365)\$(Format-String -inputString $o.displayName)`.json"
                Format-Assignment -policy $o | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region Proactive Remediation Scripts
        if ($config.proactiveRemediation) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Remediation Scripts           " -NoNewline -ForegroundColor Green
            "`n## Proactive Remediation Scripts`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($s in $config.proactiveRemediation) {
                $displayName = $null
                $displayName = Format-String -inputString $s.displayName
                #store the script contents locally
                New-Item "$($paths.prScripts)\$displayName" -ItemType Directory -Force | Out-Null
                #TODO: finish this section
                [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($s.detectionScriptContent)")) |
                Out-File -FilePath "$($paths.prScripts)\$displayName\detection.ps1" -Encoding ascii -Force
                [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($s.remediationScriptContent)")) |
                Out-File -FilePath "$($paths.prScripts)\$displayName\remediation`.ps1" -Encoding ascii -Force

                $fpParam = @{
                    policy         = $($s | Select-Object * -ExcludeProperty detectionScriptContent,remediationScriptContent)
                    markdownReport = $markdownReport
                    outFile        = "$($paths.prScripts)\$displayName\$displayName`.json"
                }
                Format-Policy @fpParam
                Format-Assignment -policy $s | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            }
            "`n---`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
        }
        #endregion
        #region win32 Applications
        if ($config.win32Apps) {
            Write-Host "`rGenerating Report:" -NoNewline -ForegroundColor Yellow
            Write-Host " Win32 Applications           " -NoNewline -ForegroundColor Green
            "`n## Win32 Applications`n" | Out-File $markdownReport -Encoding ascii -NoNewline -Append
            foreach ($a in $config.win32Apps) {
                Format-Policy -policy $a -markdownReport $markdownReport -outFile "$($paths.apps)\$(Format-String -inputString $a.displayName)`.json"
                Format-Assignment -policy $a | Out-File $markdownReport -Encoding ascii -NoNewline -Append
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
            Write-Host " $markdownReport 🍻`n" -ForegroundColor Yellow
        }
    }
}

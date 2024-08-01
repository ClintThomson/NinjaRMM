# Clint Thomson
# Debloat Script
# Date: 2024-05-31
# Description: This script is designed to debloat Windows by removing unwanted applications and settings.

param (
    [string]$customwhitelist
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Enhanced logging function
function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$level] - $message"
    Write-Host $logEntry
}

# Check for administrative privileges
Try {
    If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log "You do not have Administrator rights to run this script. Please run the script as an Administrator." "ERROR"
        Exit 1
    }
    Write-Log "Administrative privileges confirmed."
} Catch {
    Write-Log "Error checking administrative privileges: $($_.Exception.Message)" "ERROR"
    Exit 1
}

# Create Folder
$DebloatFolder = "C:\Celeratec\Logs"
Try {
    If (Test-Path $DebloatFolder) {
        Write-Log "$DebloatFolder exists. Skipping."
    } Else {
        Write-Log "The folder '$DebloatFolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
        Start-Sleep 1
        New-Item -Path "$DebloatFolder" -ItemType Directory
        Write-Log "The folder $DebloatFolder was successfully created."
    }
} Catch {
    Write-Log "Error creating folder ${DebloatFolder}: $($_.Exception.Message)" "ERROR"
    Exit 1
}

# Start transcript
Try {
    Start-Transcript -Path "C:\Celeratec\Logs\DebloatTranscript.log" -Append
    Write-Log "Transcript started."
} Catch {
    Write-Log "Error starting transcript: $($_.Exception.Message)" "ERROR"
}

# Enhanced Remove AppX Packages function
function Remove-AppxPackages {
    param (
        [array]$whitelistedApps,
        [array]$nonRemovable
    )
    $appsToIgnore = $whitelistedApps + $nonRemovable

    function Remove-PackageWithRetry {
        param (
            [scriptblock]$removeCommand,
            [string]$packageName
        )
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                & $removeCommand
                Write-Log "Successfully removed $packageName."
                break
            } Catch {
                Write-Log "Attempt $($i+1) to remove ${packageName} failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to remove $packageName after 3 attempts." "ERROR"
                }
            }
        }
    }

    Try {
        $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -notin $appsToIgnore}
        foreach ($package in $provisionedPackages) {
            Write-Log "Attempting to remove provisioned package: $(${package.DisplayName})"
            Remove-PackageWithRetry -removeCommand {Remove-AppxProvisionedPackage -PackageName $package.PackageName -Online -ErrorAction Stop} -packageName $package.DisplayName
        }

        $appxPackages = Get-AppxPackage -AllUsers | Where-Object {$_.Name -notin $appsToIgnore}
        foreach ($package in $appxPackages) {
            Write-Log "Attempting to remove Appx package: $(${package.Name})"
            Remove-PackageWithRetry -removeCommand {Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop} -packageName $package.Name
        }
    } Catch {
        Write-Log "Error removing AppX packages: $($_.Exception.Message)" "ERROR"
    }
}

$whitelistedApps = @(
    'Microsoft.WindowsNotepad',
    'Microsoft.CompanyPortal',
    'Microsoft.ScreenSketch',
    'Microsoft.Paint3D',
    'Microsoft.WindowsCalculator',
    'Microsoft.WindowsStore',
    'Microsoft.Windows.Photos',
    'CanonicalGroupLimited.UbuntuonWindows',
    'Microsoft.MicrosoftStickyNotes',
    'Microsoft.MSPaint',
    'Microsoft.WindowsCamera',
    '.NET',
    'Framework',
    'Microsoft.HEIFImageExtension',
    'Microsoft.StorePurchaseApp',
    'Microsoft.VP9VideoExtensions',
    'Microsoft.WebMediaExtensions',
    'Microsoft.WebpImageExtension',
    'Microsoft.DesktopAppInstaller',
    'WindSynthBerry',
    'MIDIBerry',
    'Slack'
)

if ($customwhitelist) {
    $customWhitelistApps = $customwhitelist -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($whitelistapp in $customWhitelistApps) {
        $whitelistedApps += $whitelistapp
    }
}

$nonRemovable = @(
    '1527c705-839a-4832-9118-54d4Bd6a0c89',
    'c5e2524a-ea46-4f67-841f-6a9465d9d515',
    'E2A4F912-2574-4A75-9BB0-0D023378592B',
    'F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE',
    'InputApp',
    'Microsoft.AAD.BrokerPlugin',
    'Microsoft.AccountsControl',
    'Microsoft.BioEnrollment',
    'Microsoft.CredDialogHost',
    'Microsoft.ECApp',
    'Microsoft.LockApp',
    'Microsoft.MicrosoftEdgeDevToolsClient',
    'Microsoft.MicrosoftEdge',
    'Microsoft.PPIProjection',
    'Microsoft.Win32WebViewHost',
    'Microsoft.Windows.Apprep.ChxApp',
    'Microsoft.Windows.AssignedAccessLockApp',
    'Microsoft.Windows.CapturePicker',
    'Microsoft.Windows.CloudExperienceHost',
    'Microsoft.Windows.ContentDeliveryManager',
    'Microsoft.Windows.Cortana',
    'Microsoft.Windows.NarratorQuickStart',
    'Microsoft.Windows.ParentalControls',
    'Microsoft.Windows.PeopleExperienceHost',
    'Microsoft.Windows.PinningConfirmationDialog',
    'Microsoft.Windows.SecHealthUI',
    'Microsoft.Windows.SecureAssessmentBrowser',
    'Microsoft.Windows.ShellExperienceHost',
    'Microsoft.Windows.XGpuEjectDialog',
    'Microsoft.XboxGameCallableUI',
    'Windows.CBSPreview',
    'windows.immersivecontrolpanel',
    'Windows.PrintDialog',
    'Microsoft.VCLibs.140.00',
    'Microsoft.Services.Store.Engagement',
    'Microsoft.UI.Xaml.2.0',
    '*Nvidia*'
)

Remove-AppxPackages -whitelistedApps $whitelistedApps -nonRemovable $nonRemovable

# Enhanced function to remove bloatware
function Remove-Bloatware {
    param (
        [array]$bloatware,
        [string]$customwhitelist
    )

    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $bloatware = $bloatware | Where-Object { $customWhitelistApps -notcontains $_ }
    }

    function Remove-PackageWithRetry {
        param (
            [scriptblock]$removeCommand,
            [string]$packageName
        )
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                & $removeCommand
                Write-Log "Successfully removed $packageName."
                break
            } Catch {
                Write-Log "Attempt $($i+1) to remove ${packageName} failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to remove $packageName after 3 attempts." "ERROR"
                }
            }
        }
    }

    foreach ($bloat in $bloatware) {
        Try {
            $provisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $bloat -ErrorAction SilentlyContinue
            if ($provisionedPackage) {
                Write-Log "Attempting to remove provisioned package for ${bloat}."
                Remove-PackageWithRetry -removeCommand {Remove-AppxProvisionedPackage -PackageName $provisionedPackage.PackageName -Online -ErrorAction Stop} -packageName $bloat
            } else {
                Write-Log "Provisioned package for $bloat not found."
            }

            $appxPackage = Get-AppxPackage -AllUsers | Where-Object Name -like $bloat -ErrorAction SilentlyContinue
            if ($appxPackage) {
                Write-Log "Attempting to remove ${bloat}."
                Remove-PackageWithRetry -removeCommand {Remove-AppxPackage -Package $appxPackage.PackageFullName -AllUsers -ErrorAction Stop} -packageName $bloat
            } else {
                Write-Log "$bloat not found."
            }
        } Catch {
            Write-Log "Error removing bloatware ${bloat}: $($_.Exception.Message)" "ERROR"
        }
    }
}

$bloatware = @(
    "Microsoft.549981C3F5F10",
    "Microsoft.BingNews",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.NetworkSpeedTest",
    "Microsoft.MixedReality.Portal",
    "Microsoft.News",
    "Microsoft.Office.Lens",
    "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway",
    "Microsoft.OneConnect",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.RemoteDesktop",
    "Microsoft.SkypeApp",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Office.Todo.List",
    "Microsoft.Whiteboard",
    "Microsoft.WindowsAlarms",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftTeams",
    "Microsoft.YourPhone",
    "Microsoft.XboxGamingOverlay_5.721.10202.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.GamingApp",
    "Microsoft.Todos",
    "Microsoft.PowerAutomateDesktop",
    "SpotifyAB.SpotifyMusic",
    "Microsoft.MicrosoftJournal",
    "Disney.37853FC22B2CE",
    "*EclipseManager*",
    "*ActiproSoftwareLLC*",
    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*",
    "*Duolingo-LearnLanguagesforFree*",
    "*PandoraMediaInc*",
    "*CandyCrush*",
    "*BubbleWitch3Saga*",
    "*Wunderlist*",
    "*Flipboard*",
    "*Twitter*",
    "*Facebook*",
    "*Spotify*",
    "*Minecraft*",
    "*Royal Revolt*",
    "*Sway*",
    "*Speed Test*",
    "*Dolby*",
    "*Office*",
    "*Disney*",
    "clipchamp.clipchamp",
    "*gaming*",
    "MicrosoftCorporationII.MicrosoftFamily",
    "C27EB4BA.DropboxOEM*",
    "*DevHome*",
    "MicrosoftCorporationII.QuickAssist"
)

Remove-Bloatware -bloatware $bloatware -customwhitelist $customwhitelist

# Enhanced function to remove registry keys
function Remove-RegistryKeys {
    param (
        [array]$keys
    )

    function Remove-KeyWithRetry {
        param (
            [string]$key
        )
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Remove-Item $key -Recurse -ErrorAction Stop
                Write-Log "Successfully removed $key from registry."
                break
            } Catch {
                Write-Log "Attempt $($i+1) to remove ${key} from registry failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to remove $key from registry after 3 attempts." "ERROR"
                }
            }
        }
    }

    foreach ($key in $keys) {
        Try {
            Write-Log "Removing ${key} from registry"
            Remove-KeyWithRetry -key $key
        } Catch {
            Write-Log "Error removing registry key ${key}: $($_.Exception.Message)" "ERROR"
        }
    }
}

$keys = @(
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
    "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
)

Remove-RegistryKeys -keys $keys

# Disable Windows Feedback Experience
function Disable-WindowsFeedback {
    Try {
        Write-Log "Disabling Windows Feedback Experience program"
        $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        If (!(Test-Path $Advertising)) {
            New-Item $Advertising
            Write-Log "Created registry path: $Advertising"
        }
        If (Test-Path $Advertising) {
            Set-ItemProperty $Advertising Enabled -Value 0
            Write-Log "Set Enabled property to 0 at $Advertising"
        }
        Write-Log "Windows Feedback Experience disabled"
    } Catch {
        Write-Log "Error disabling Windows Feedback Experience: $($_.Exception.Message)" "ERROR"
    }
}

Disable-WindowsFeedback

# Stop Cortana from being used as part of your Windows Search Function
function Stop-CortanaSearch {
    Try {
        Write-Log "Stopping Cortana from being used as part of your Windows Search Function"
        $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        If (!(Test-Path $Search)) {
            New-Item $Search
            Write-Log "Created registry path: $Search"
        }
        If (Test-Path $Search) {
            Set-ItemProperty $Search AllowCortana -Value 0
            Write-Log "Set AllowCortana property to 0 at $Search"
        }
        Write-Log "Cortana stopped from being used in Windows Search Function"
    } Catch {
        Write-Log "Error stopping Cortana from being used in Windows Search Function: $($_.Exception.Message)" "ERROR"
    }
}

Stop-CortanaSearch

# Disable Web Search in Start Menu
function Disable-WebSearch {
    Try {
        Write-Log "Disabling Bing Search in Start Menu"
        $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        
        if (!(Test-Path $WebSearch)) {
            New-Item $WebSearch
            Write-Log "Created registry path: $WebSearch"
        }
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty $WebSearch DisableWebSearch -Value 1
                Write-Log "Set DisableWebSearch property to 1 at $WebSearch"
                Write-Log "Bing Search disabled in Start Menu"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set DisableWebSearch property at ${WebSearch} failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set DisableWebSearch property at $WebSearch after 3 attempts." "ERROR"
                }
            }
        }
    } Catch {
        Write-Log "Error disabling Bing Search in Start Menu: $($_.Exception.Message)" "ERROR"
    }
}

Disable-WebSearch

# Loop through all user SIDs in the registry and disable Bing Search
function Disable-BingSearchForAllUsers {
    Try {
        Write-Log "Disabling Bing Search for all users"
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $WebSearch = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
            if (!(Test-Path $WebSearch)) {
                New-Item $WebSearch
                Write-Log "Created registry path: $WebSearch for user SID: $sid"
            }
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $WebSearch BingSearchEnabled -Value 0
                    Write-Log "Set BingSearchEnabled property to 0 at $WebSearch for user SID: $sid"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set BingSearchEnabled property at ${WebSearch} for user SID: ${sid} failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set BingSearchEnabled property at $WebSearch for user SID: $sid after 3 attempts." "ERROR"
                    }
                }
            }
        }
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled -Value 0
                Write-Log "Set BingSearchEnabled property to 0 at HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
                Write-Log "Bing Search disabled for all users"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set BingSearchEnabled property at HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set BingSearchEnabled property at HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search after 3 attempts." "ERROR"
                }
            }
        }
    } Catch {
        Write-Log "Error disabling Bing Search for all users: $($_.Exception.Message)" "ERROR"
    }
}

Disable-BingSearchForAllUsers

# Stop the Windows Feedback Experience from sending anonymous data
function Stop-FeedbackData {
    Try {
        Write-Log "Stopping the Windows Feedback Experience program"
        $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
        If (!(Test-Path $Period)) {
            New-Item $Period
            Write-Log "Created registry path: $Period"
        }
        Set-ItemProperty $Period PeriodInNanoSeconds -Value 0
        Write-Log "Set PeriodInNanoSeconds property to 0 at $Period"
        Write-Log "Windows Feedback Experience program stopped"
    } Catch {
        Write-Log "Error stopping the Windows Feedback Experience program: $($_.Exception.Message)" "ERROR"
    }
}

Stop-FeedbackData

# Loop and do the same for all user SIDs
function Stop-FeedbackDataForAllUsers {
    Try {
        Write-Log "Stopping the Windows Feedback Experience program for all users"
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $Period = "Registry::HKU\$sid\Software\Microsoft\Siuf\Rules"
            if (!(Test-Path $Period)) {
                New-Item $Period
                Write-Log "Created registry path: $Period for user SID: $sid"
            }
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $Period PeriodInNanoSeconds -Value 0
                    Write-Log "Set PeriodInNanoSeconds property to 0 at $Period for user SID: $sid"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set PeriodInNanoSeconds property at $Period for user SID: $sid failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set PeriodInNanoSeconds property at $Period for user SID: $sid after 3 attempts." "ERROR"
                    }
                }
            }
        }
        Write-Log "Windows Feedback Experience program stopped for all users"
    } Catch {
        Write-Log "Error stopping the Windows Feedback Experience program for all users: $($_.Exception.Message)" "ERROR"
    }
}

Stop-FeedbackDataForAllUsers

# Prevent bloatware applications from returning and remove Start Menu suggestions
function Prevent-BloatwareReturn {
    Try {
        Write-Log "Adding Registry key to prevent bloatware apps from returning"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        If (!(Test-Path $registryPath)) {
            New-Item $registryPath
            Write-Log "Created registry path: $registryPath"
        }
        Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1
        Write-Log "Set DisableWindowsConsumerFeatures property to 1 at $registryPath"

        If (!(Test-Path $registryOEM)) {
            New-Item $registryOEM
            Write-Log "Created registry path: $registryOEM"
        }
        Set-ItemProperty $registryOEM ContentDeliveryAllowed -Value 0
        Set-ItemProperty $registryOEM OemPreInstalledAppsEnabled -Value 0
        Set-ItemProperty $registryOEM PreInstalledAppsEnabled -Value 0
        Set-ItemProperty $registryOEM PreInstalledAppsEverEnabled -Value 0
        Set-ItemProperty $registryOEM SilentInstalledAppsEnabled -Value 0
        Set-ItemProperty $registryOEM SystemPaneSuggestionsEnabled -Value 0
        Write-Log "Set ContentDelivery properties to disable bloatware apps at $registryOEM"
        Write-Log "Registry key added to prevent bloatware apps from returning"
    } Catch {
        Write-Log "Error adding Registry key to prevent bloatware apps from returning: $($_.Exception.Message)" "ERROR"
    }
}

Prevent-BloatwareReturn

# Loop through users and do the same
function Prevent-BloatwareReturnForAllUsers {
    Try {
        Write-Log "Adding Registry key to prevent bloatware apps from returning for all users"
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $registryOEM = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            if (!(Test-Path $registryOEM)) {
                New-Item $registryOEM
                Write-Log "Created registry path: $registryOEM for user SID: $sid"
            }
            $properties = @{
                ContentDeliveryAllowed = 0
                OemPreInstalledAppsEnabled = 0
                PreInstalledAppsEnabled = 0
                PreInstalledAppsEverEnabled = 0
                SilentInstalledAppsEnabled = 0
                SystemPaneSuggestionsEnabled = 0
            }
            foreach ($property in $properties.Keys) {
                for ($i = 0; $i -lt 3; $i++) {
                    Try {
                        Set-ItemProperty $registryOEM $property -Value $properties[$property]
                        Write-Log "Set $property property to $($properties[$property]) at $registryOEM for user SID: $sid"
                        break
                    } Catch {
                        Write-Log "Attempt $($i+1) to set $property property at $registryOEM for user SID: $sid failed: $($_.Exception.Message)" "ERROR"
                        Start-Sleep -Seconds 5
                        if ($i -eq 2) {
                            Write-Log "Failed to set $property property at $registryOEM for user SID: $sid after 3 attempts." "ERROR"
                        }
                    }
                }
            }
        }
        Write-Log "Registry key added to prevent bloatware apps from returning for all users"
    } Catch {
        Write-Log "Error adding Registry key to prevent bloatware apps from returning for all users: $($_.Exception.Message)" "ERROR"
    }
}

Prevent-BloatwareReturnForAllUsers

# Prepare Mixed Reality Portal for removal
function Prepare-MixedRealityPortalRemoval {
    Try {
        Write-Log "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
        $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
        if (Test-Path $Holo) {
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $Holo FirstRunSucceeded -Value 0
                    Write-Log "Set FirstRunSucceeded property to 0 at $Holo"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set FirstRunSucceeded property at $Holo failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set FirstRunSucceeded property at $Holo after 3 attempts." "ERROR"
                    }
                }
            }
        }

        # Loop through users and do the same
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $Holo = "Registry::HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Holographic"
            if (Test-Path $Holo) {
                for ($i = 0; $i -lt 3; $i++) {
                    Try {
                        Set-ItemProperty $Holo FirstRunSucceeded -Value 0
                        Write-Log "Set FirstRunSucceeded property to 0 at $Holo for user SID: $sid"
                        break
                    } Catch {
                        Write-Log "Attempt $($i+1) to set FirstRunSucceeded property at $Holo for user SID: $sid failed: $($_.Exception.Message)" "ERROR"
                        Start-Sleep -Seconds 5
                        if ($i -eq 2) {
                            Write-Log "Failed to set FirstRunSucceeded property at $Holo for user SID: $sid after 3 attempts." "ERROR"
                        }
                    }
                }
            }
        }
        Write-Log "Mixed Reality Portal value set to 0 for all users"
    } Catch {
        Write-Log "Error setting Mixed Reality Portal value to 0: $($_.Exception.Message)" "ERROR"
    }
}

Prepare-MixedRealityPortalRemoval

# Disable Wi-Fi Sense
function Disable-WiFiSense {
    Try {
        Write-Log "Disabling Wi-Fi Sense"
        $WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
        $WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
        $WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"

        for ($i = 0; $i -lt 3; $i++) {
            Try {
                if (!(Test-Path $WifiSense1)) {
                    New-Item $WifiSense1
                    Write-Log "Created registry path: $WifiSense1"
                }
                Set-ItemProperty $WifiSense1 Value -Value 0
                Write-Log "Set Value property to 0 at $WifiSense1"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set Value property at $WifiSense1 failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set Value property at $WifiSense1 after 3 attempts." "ERROR"
                }
            }
        }

        for ($i = 0; $i -lt 3; $i++) {
            Try {
                if (!(Test-Path $WifiSense2)) {
                    New-Item $WifiSense2
                    Write-Log "Created registry path: $WifiSense2"
                }
                Set-ItemProperty $WifiSense2 Value -Value 0
                Write-Log "Set Value property to 0 at $WifiSense2"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set Value property at $WifiSense2 failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set Value property at $WifiSense2 after 3 attempts." "ERROR"
                }
            }
        }

        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty $WifiSense3 AutoConnectAllowedOEM -Value 0
                Write-Log "Set AutoConnectAllowedOEM property to 0 at $WifiSense3"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set AutoConnectAllowedOEM property at $WifiSense3 failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set AutoConnectAllowedOEM property at $WifiSense3 after 3 attempts." "ERROR"
                }
            }
        }

        Write-Log "Wi-Fi Sense disabled"
    } Catch {
        Write-Log "Error disabling Wi-Fi Sense: $($_.Exception.Message)" "ERROR"
    }
}

Disable-WiFiSense

# Disable Live Tiles
function Disable-LiveTiles {
    Try {
        Write-Log "Disabling live tiles"
        $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
        
        if (!(Test-Path $Live)) {
            New-Item $Live
            Write-Log "Created registry path: $Live"
        }
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty $Live NoTileApplicationNotification -Value 1
                Write-Log "Set NoTileApplicationNotification property to 1 at $Live"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set NoTileApplicationNotification property at $Live failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set NoTileApplicationNotification property at $Live after 3 attempts." "ERROR"
                }
            }
        }

        # Loop through users and do the same
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $Live = "Registry::HKU\$sid\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
            if (!(Test-Path $Live)) {
                New-Item $Live
                Write-Log "Created registry path: $Live for user SID: $sid"
            }
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $Live NoTileApplicationNotification -Value 1
                    Write-Log "Set NoTileApplicationNotification property to 1 at $Live for user SID: $sid"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set NoTileApplicationNotification property at ${Live} for user SID: ${sid} failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set NoTileApplicationNotification property at $Live for user SID: $sid after 3 attempts." "ERROR"
                    }
                }
            }
        }
        Write-Log "Live tiles disabled"
    } Catch {
        Write-Log "Error disabling live tiles: $($_.Exception.Message)" "ERROR"
    }
}

Disable-LiveTiles

# Disable People icon on Taskbar
function Disable-PeopleIcon {
    Try {
        Write-Log "Disabling People icon on Taskbar"
        $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
        
        if (Test-Path $People) {
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $People -Name PeopleBand -Value 0
                    Write-Log "Set PeopleBand property to 0 at $People"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set PeopleBand property at $People failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set PeopleBand property at $People after 3 attempts." "ERROR"
                    }
                }
            }
        }

        # Loop through users and do the same
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $People = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
            
            if (Test-Path $People) {
                for ($i = 0; $i -lt 3; $i++) {
                    Try {
                        Set-ItemProperty $People -Name PeopleBand -Value 0
                        Write-Log "Set PeopleBand property to 0 at $People for user SID: $sid"
                        break
                    } Catch {
                        Write-Log "Attempt $($i+1) to set PeopleBand property at ${People} for user SID: ${sid} failed: $($_.Exception.Message)" "ERROR"
                        Start-Sleep -Seconds 5
                        if ($i -eq 2) {
                            Write-Log "Failed to set PeopleBand property at $People for user SID: $sid after 3 attempts." "ERROR"
                        }
                    }
                }
            }
        }
        Write-Log "People icon disabled on Taskbar for all users"
    } Catch {
        Write-Log "Error disabling People icon on Taskbar: $($_.Exception.Message)" "ERROR"
    }
}

Disable-PeopleIcon

# Disable Cortana
function Disable-Cortana {
    Try {
        Write-Log "Disabling Cortana"
        $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
        $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
        $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        
        if (!(Test-Path $Cortana1)) {
            New-Item $Cortana1
            Write-Log "Created registry path: $Cortana1"
        }
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0
                Write-Log "Set AcceptedPrivacyPolicy property to 0 at $Cortana1"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set AcceptedPrivacyPolicy property at $Cortana1 failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set AcceptedPrivacyPolicy property at $Cortana1 after 3 attempts." "ERROR"
                }
            }
        }

        if (!(Test-Path $Cortana2)) {
            New-Item $Cortana2
            Write-Log "Created registry path: $Cortana2"
        }
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1
                Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1
                Write-Log "Set RestrictImplicitTextCollection and RestrictImplicitInkCollection properties to 1 at $Cortana2"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set properties at ${Cortana2} failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set properties at $Cortana2 after 3 attempts." "ERROR"
                }
            }
        }

        if (!(Test-Path $Cortana3)) {
            New-Item $Cortana3
            Write-Log "Created registry path: $Cortana3"
        }
        for ($i = 0; $i -lt 3; $i++) {
            Try {
                Set-ItemProperty $Cortana3 HarvestContacts -Value 0
                Write-Log "Set HarvestContacts property to 0 at $Cortana3"
                break
            } Catch {
                Write-Log "Attempt $($i+1) to set HarvestContacts property at $Cortana3 failed: $($_.Exception.Message)" "ERROR"
                Start-Sleep -Seconds 5
                if ($i -eq 2) {
                    Write-Log "Failed to set HarvestContacts property at $Cortana3 after 3 attempts." "ERROR"
                }
            }
        }

        # Loop through users and do the same
        $UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName
        foreach ($sid in $UserSIDs) {
            $Cortana1 = "Registry::HKU\$sid\SOFTWARE\Microsoft\Personalization\Settings"
            $Cortana2 = "Registry::HKU\$sid\SOFTWARE\Microsoft\InputPersonalization"
            $Cortana3 = "Registry::HKU\$sid\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
            
            if (!(Test-Path $Cortana1)) {
                New-Item $Cortana1
                Write-Log "Created registry path: $Cortana1 for user SID: $sid"
            }
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0
                    Write-Log "Set AcceptedPrivacyPolicy property to 0 at $Cortana1 for user SID: $sid"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set AcceptedPrivacyPolicy property at $Cortana1 for user SID: $sid failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set AcceptedPrivacyPolicy property at $Cortana1 for user SID: $sid after 3 attempts." "ERROR"
                    }
                }
            }

            if (!(Test-Path $Cortana2)) {
                New-Item $Cortana2
                Write-Log "Created registry path: $Cortana2 for user SID: $sid"
            }
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1
                    Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1
                    Write-Log "Set RestrictImplicitTextCollection and RestrictImplicitInkCollection properties to 1 at $Cortana2 for user SID: $sid"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set properties at $Cortana2 for user SID: $sid failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set properties at $Cortana2 for user SID: $sid after 3 attempts." "ERROR"
                    }
                }
            }

            if (!(Test-Path $Cortana3)) {
                New-Item $Cortana3
                Write-Log "Created registry path: $Cortana3 for user SID: $sid"
            }
            for ($i = 0; $i -lt 3; $i++) {
                Try {
                    Set-ItemProperty $Cortana3 HarvestContacts -Value 0
                    Write-Log "Set HarvestContacts property to 0 at $Cortana3 for user SID: $sid"
                    break
                } Catch {
                    Write-Log "Attempt $($i+1) to set HarvestContacts property at ${Cortana3} for user SID: ${sid} failed: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds 5
                    if ($i -eq 2) {
                        Write-Log "Failed to set HarvestContacts property at $Cortana3 for user SID: $sid after 3 attempts." "ERROR"
                    }
                }
            }
        }
        Write-Log "Cortana disabled"
    } Catch {
        Write-Log "Error disabling Cortana: $($_.Exception.Message)" "ERROR"
    }
}

Disable-Cortana

# Remove 3D Objects from the 'My Computer' submenu in explorer
function Remove-3DObjects {
    Try {
        Write-Log "Removing 3D Objects from explorer 'My Computer' submenu"
        $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        If (Test-Path $Objects32) {
            Remove-Item $Objects32 -Recurse
            Write-Log "Removed $Objects32"
        }
        If (Test-Path $Objects64) {
            Remove-Item $Objects64 -Recurse
            Write-Log "Removed $Objects64"
        }
        Write-Log "3D Objects removed from explorer 'My Computer' submenu"
    } Catch {
        Write-Log "Error removing 3D Objects from explorer 'My Computer' submenu: $($_.Exception.Message)" "ERROR"
    }
}

Remove-3DObjects

# Remove the Microsoft Feeds from displaying
function Remove-MicrosoftFeeds {
    Try {
        Write-Log "Removing Microsoft Feeds from displaying"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
        $Name = "EnableFeeds"
        $value = "0"

        if (!(Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
            Write-Log "Created registry path: $registryPath"
        }
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        Write-Log "Set EnableFeeds property to 0 at $registryPath"
        Write-Log "Microsoft Feeds removed from displaying"
    } Catch {
        Write-Log "Error removing Microsoft Feeds from displaying: $($_.Exception.Message)" "ERROR"
    }
}

Remove-MicrosoftFeeds

# Kill Cortana again
function Kill-Cortana {
    Try {
        Write-Log "Removing Cortana again"
        Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 | Remove-AppxPackage
        Write-Log "Cortana removed again"
    } Catch {
        Write-Log "Error removing Cortana again: $($_.Exception.Message)" "ERROR"
    }
}

Kill-Cortana

# Disable scheduled tasks
function Disable-ScheduledTasks {
    Try {
        Write-Log "Disabling scheduled tasks"
        $taskNames = @("XblGameSaveTaskLogon", "XblGameSaveTask", "Consolidator", "UsbCeip", "DmClient", "DmClientOnScenarioDownload")
        foreach ($taskName in $taskNames) {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($null -ne $task) {
                Disable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                Write-Log "Disabled scheduled task: $taskName"
            } else {
                Write-Log "Scheduled task not found: $taskName"
            }
        }
        Write-Log "Scheduled tasks disabled"
    } Catch {
        Write-Log "Error disabling scheduled tasks: $($_.Exception.Message)" "ERROR"
    }
}

Disable-ScheduledTasks

# Disable DiagTrack Services
function Disable-DiagTrackServices {
    Try {
        Write-Log "Stopping and disabling Diagnostics Tracking Service"
        Stop-Service "DiagTrack"
        Set-Service "DiagTrack" -StartupType Disabled
        Write-Log "Diagnostics Tracking Service stopped and disabled"
    } Catch {
        Write-Log "Error stopping and disabling Diagnostics Tracking Service: $($_.Exception.Message)" "ERROR"
    }
}

Disable-DiagTrackServices

# Windows 11 Specific Customizations
function Windows11-Customizations {
    Try {
        Write-Log "Removing Windows 11 Customizations"
        $packages = @(
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxGameCallableUI",
            "Microsoft.549981C3F5F10",
            "*getstarted*",
            "Microsoft.Windows.ParentalControls"
        )

        if ($customwhitelist) {
            $customWhitelistApps = $customwhitelist -split ","
            $packages = $packages | Where-Object { $customWhitelistApps -notcontains $_ }
        }

        foreach ($package in $packages) {
            $appPackage = Get-AppxPackage -AllUsers $package -ErrorAction SilentlyContinue
            if ($appPackage) {
                Remove-AppxPackage -Package $appPackage.PackageFullName -AllUsers
                Write-Log "Removed $package"
            }
        }
        Write-Log "Windows 11 Customizations removed"
    } Catch {
        Write-Log "Error removing Windows 11 Customizations: $($_.Exception.Message)" "ERROR"
    }
}

Windows11-Customizations

# Remove Teams Chat
function Remove-TeamsChat {
    Try {
        Write-Log "Removing Teams Chat"
        $MSTeams = "MicrosoftTeams"
        $WinPackage = Get-AppxPackage -AllUsers | Where-Object {$_.Name -eq $MSTeams}
        $ProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $WinPackage }
        If ($null -ne $WinPackage) {
            Remove-AppxPackage -Package $WinPackage.PackageFullName -AllUsers
            Write-Log "Removed $MSTeams AppxPackage"
        }
        If ($null -ne $ProvisionedPackage) {
            Remove-AppxProvisionedPackage -Online -Packagename $ProvisionedPackage.Packagename -AllUsers
            Write-Log "Removed $MSTeams ProvisionedPackage"
        }

        # Tweak registry permissions
        Invoke-WebRequest -Uri "https://dfwmsp.com/RMS/SetACL.exe" -OutFile "C:\Celeratec\SetACL.exe"
        C:\Celeratec\SetACL.exe -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -ot reg -actn setowner -ownr "n:$everyone"
        C:\Celeratec\SetACL.exe -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -ot reg -actn ace -ace "n:$everyone;p:full"
        Write-Log "Tweaked registry permissions for Communications"

        # Stop it from coming back
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications"
        If (!(Test-Path $registryPath)) {
            New-Item $registryPath
            Write-Log "Created registry path: $registryPath"
        }
        Set-ItemProperty $registryPath ConfigureChatAutoInstall -Value 0
        Write-Log "Set ConfigureChatAutoInstall property to 0 at $registryPath"

        # Unpin it
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
        If (!(Test-Path $registryPath)) {
            New-Item $registryPath
            Write-Log "Created registry path: $registryPath"
        }
        Set-ItemProperty $registryPath "ChatIcon" -Value 2
        Write-Log "Set ChatIcon property to 2 at $registryPath"
        Write-Log "Removed Teams Chat"
    } Catch {
        Write-Log "Error removing Teams Chat: $($_.Exception.Message)" "ERROR"
    }
}

Remove-TeamsChat

# Disable Feeds
function Disable-Feeds {
    Try {
        Write-Log "Disabling Feeds"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
        If (!(Test-Path $registryPath)) {
            New-Item $registryPath
            Write-Log "Created registry path: $registryPath"
        }
        Set-ItemProperty $registryPath "AllowNewsAndInterests" -Value 0
        Write-Log "Set AllowNewsAndInterests property to 0 at $registryPath"
        Write-Log "Disabled Feeds"
    } Catch {
        Write-Log "Error disabling Feeds: $($_.Exception.Message)" "ERROR"
    }
}

Disable-Feeds

# Windows Backup App
function Remove-WindowsBackupApp {
    Try {
        Write-Log "Removing Windows Backup"
        $version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
        if ($version -like "*Windows 10*") {
            $filepath = "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\WindowsBackup\Assets"
            if (Test-Path $filepath) {
                Remove-WindowsPackage -Online -PackageName "Microsoft-Windows-UserExperience-Desktop-Package~31bf3856ad364e35~amd64~~10.0.19041.3393"
                Write-Log "Removed Windows Backup package"

                # Add back snipping tool functionality
                Write-Log "Adding Windows Shell Components"
                DISM /Online /Add-Capability /CapabilityName:Windows.Client.ShellComponents~~~~0.0.1.0
                Write-Log "Components Added"
            }
        }
        Write-Log "Windows Backup removed"
    } Catch {
        Write-Log "Error removing Windows Backup: $($_.Exception.Message)" "ERROR"
    }
}

Remove-WindowsBackupApp

# Windows CoPilot
function Remove-WindowsCoPilot {
    Try {
        Write-Log "Removing Windows Copilot"
        $version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
        if ($version -like "*Windows 11*") {
            # Define the registry key and value
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            $propertyName = "TurnOffWindowsCopilot"
            $propertyValue = 1

            # Check if the registry key exists
            if (!(Test-Path $registryPath)) {
                # If the registry key doesn't exist, create it
                New-Item -Path $registryPath -Force | Out-Null
                Write-Log "Created registry path: $registryPath"
            }

            # Get the property value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue

            # Check if the property exists and if its value is different from the desired value
            if ($null -eq $currentValue) {
                # If the property doesn't exist, create it with the desired value
                New-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue -PropertyType DWORD -Force | Out-Null
                Write-Log "Created $propertyName with value $propertyValue at $registryPath"
            } elseif ($currentValue.$propertyName -ne $propertyValue) {
                # If the property exists but its value is different, update the value
                Set-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue -Force | Out-Null
                Write-Log "Set $propertyName to $propertyValue at $registryPath"
            }

            Write-Log "Windows Copilot removed"
        }
    } Catch {
        Write-Log "Error removing Windows Copilot: $($_.Exception.Message)" "ERROR"
    }
}

Remove-WindowsCoPilot

# Kill process after debloat
function Stop-ProcessAfterDebloat {
    Try {
        Write-Log "Stopping processes after debloat"
        Get-Process | Where-Object { $_.Name -in @('YourPhone', 'CommunicationsApps', 'Microsoft.Photos', 'MixedReality.Portal') } | Stop-Process -Force
        Write-Log "Stopped processes after debloat"
    } Catch {
        Write-Log "Error stopping processes after debloat: $($_.Exception.Message)" "ERROR"
    }
}

Stop-ProcessAfterDebloat

# Clear Start Menu
function Clear-StartMenu {
    Try {
        Write-Log "Clearing Start Menu"
        $version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
        if ($version -like "*Windows 10*") {
            Write-Log "Windows 10 Detected"
            Write-Log "Removing Current Layout"
            If (Test-Path "C:\Windows\StartLayout.xml") {
                Remove-Item "C:\Windows\StartLayout.xml"
            }
            Write-Log "Creating Default Layout"
            @"
            <LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
            <LayoutOptions StartTileGroupCellWidth="6" />
            <DefaultLayoutOverride>
             <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
             </StartLayoutCollection>
             </DefaultLayoutOverride>
            </LayoutModificationTemplate>
"@ | Out-File "C:\Windows\StartLayout.xml"
        } elseif ($version -like "*Windows 11*") {
            Write-Log "Windows 11 Detected"
            Write-Log "Removing Current Layout"
            If (Test-Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml") {
                Remove-Item "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
            }
            $blankjson = @'
{
    "pinnedList": [
        { "desktopAppId": "MSEdge" },
        { "packagedAppId": "Microsoft.WindowsStore_8wekyb3d8bbwe!App" },
        { "desktopAppId": "Microsoft.Windows.Explorer" }
    ]
}
'@
            $blankjson | Out-File "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Encoding utf8 -Force
        }
        Write-Log "Start Menu cleared"
    } Catch {
        Write-Log "Error clearing Start Menu: $($_.Exception.Message)" "ERROR"
    }
}

Clear-StartMenu

# Remove Xbox Gaming
function Remove-XboxGaming {
    Try {
        Write-Log "Removing Xbox Gaming"
        New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\xbgm" -Name "Start" -PropertyType DWORD -Value 4 -Force
        Set-Service -Name XblAuthManager -StartupType Disabled
        Set-Service -Name XblGameSave -StartupType Disabled
        Set-Service -Name XboxGipSvc -StartupType Disabled
        Set-Service -Name XboxNetApiSvc -StartupType Disabled
        $task = Get-ScheduledTask -TaskName "Microsoft\XblGameSave\XblGameSaveTask" -ErrorAction SilentlyContinue
        if ($null -ne $task) {
            Set-ScheduledTask -TaskPath $task.TaskPath -Enabled $false
            Write-Log "Disabled scheduled task: $($task.TaskName)"
        }

        # Check if GameBarPresenceWriter.exe exists
        if (Test-Path "$env:WinDir\System32\GameBarPresenceWriter.exe") {
            Write-Log "GameBarPresenceWriter.exe exists"
            C:\Celeratec\SetACL.exe -on "$env:WinDir\System32\GameBarPresenceWriter.exe" -ot file -actn setowner -ownr "n:$everyone"
            C:\Celeratec\SetACL.exe -on "$env:WinDir\System32\GameBarPresenceWriter.exe" -ot file -actn ace -ace "n:$everyone;p:full"
            $NewAcl = Get-Acl -Path "$env:WinDir\System32\GameBarPresenceWriter.exe"
            $identity = "$builtin\Administrators"
            $fileSystemRights = "FullControl"
            $type = "Allow"
            $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
            $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
            $NewAcl.SetAccessRule($fileSystemAccessRule)
            Set-Acl -Path "$env:WinDir\System32\GameBarPresenceWriter.exe" -AclObject $NewAcl
            Stop-Process -Name "GameBarPresenceWriter.exe" -Force
            Remove-Item "$env:WinDir\System32\GameBarPresenceWriter.exe" -Force -Confirm:$false
            Write-Log "Removed GameBarPresenceWriter.exe"
        } else {
            Write-Log "GameBarPresenceWriter.exe does not exist"
        }

        New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\GameDVR" -Name "AllowgameDVR" -PropertyType DWORD -Value 0 -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -PropertyType String -Value "hide:gaming-gamebar;gaming-gamedvr;gaming-broadcasting;gaming-gamemode;gaming-xboxnetworking" -Force
        Remove-Item C:\Celeratec\SetACL.exe -Recurse
        Write-Log "Xbox Gaming removed"
    } Catch {
        Write-Log "Error removing Xbox Gaming: $($_.Exception.Message)" "ERROR"
    }
}

Remove-XboxGaming

# Disable Edge Surf Game
function Disable-EdgeSurfGame {
    Try {
        Write-Log "Disabling Edge Surf Game"
        $surf = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge"
        If (!(Test-Path $surf)) {
            New-Item $surf
            Write-Log "Created registry path: $surf"
        }
        New-ItemProperty -Path $surf -Name 'AllowSurfGame' -Value 0 -PropertyType DWord
        Write-Log "Edge Surf Game disabled"
    } Catch {
        Write-Log "Error disabling Edge Surf Game: $($_.Exception.Message)" "ERROR"
    }
}

Disable-EdgeSurfGame

# Grab all Uninstall Strings
function Grab-UninstallStrings {
    Try {
        Write-Log "Checking 32-bit System Registry"
        $allstring = @()
        $path1 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $32apps = Get-ChildItem -Path $path1 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

        foreach ($32app in $32apps) {
            $string1 = $32app.uninstallstring
            if ($string1 -match "^msiexec*") {
                $string2 = $string1 + " /quiet /norestart"
                $string2 = $string2 -replace "/I", "/X "
                $allstring += New-Object -TypeName PSObject -Property @{
                    Name = $32app.DisplayName
                    String = $string2
                }
            } else {
                $string2 = $string1
                $allstring += New-Object -TypeName PSObject -Property @{
                    Name = $32app.DisplayName
                    String = $string2
                }
            }
        }

        Write-Log "32-bit check complete"
        Write-Log "Checking 64-bit System Registry"
        $path2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $64apps = Get-ChildItem -Path $path2 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

        foreach ($64app in $64apps) {
            $string1 = $64app.uninstallstring
            if ($string1 -match "^msiexec*") {
                $string2 = $string1 + " /quiet /norestart"
                $string2 = $string1 -replace "/I", "/X "
                $allstring += New-Object -TypeName PSObject -Property @{
                    Name = $64app.DisplayName
                    String = $string2
                }
            } else {
                $string2 = $string1
                $allstring += New-Object -TypeName PSObject -Property @{
                    Name = $64app.DisplayName
                    String = $string2
                }
            }
        }

        Write-Log "64-bit checks complete"

        Write-Log "Checking 32-bit User Registry"
        $path1 = "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        if (Test-Path $path1) {
            $32apps = Get-ChildItem -Path $path1 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString
            foreach ($32app in $32apps) {
                $string1 = $32app.uninstallstring
                if ($string1 -match "^msiexec*") {
                    $string2 = $string1 + " /quiet /norestart"
                    $string2 = $string1 -replace "/I", "/X "
                    $allstring += New-Object -TypeName PSObject -Property @{
                        Name = $32app.DisplayName
                        String = $string2
                    }
                } else {
                    $string2 = $string1
                    $allstring += New-Object -TypeName PSObject -Property @{
                        Name = $32app.DisplayName
                        String = $string2
                    }
                }
            }
        }

        Write-Log "32-bit user registry check complete"
        Write-Log "Checking 64-bit User Registry"
        $path2 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $64apps = Get-ChildItem -Path $path2 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

        foreach ($64app in $64apps) {
            $string1 = $64app.uninstallstring
            if ($string1 -match "^msiexec*") {
                $string2 = $string1 + " /quiet /norestart"
                $string2 = $string1 -replace "/I", "/X "
                $allstring += New-Object -TypeName PSObject -Property @{
                    Name = $64app.DisplayName
                    String = $string2
                }
            } else {
                $string2 = $string1
                $allstring += New-Object -TypeName PSObject -Property @{
                    Name = $64app.DisplayName
                    String = $string2
                }
            }
        }
        Write-Log "64-bit user registry check complete"
    } Catch {
        Write-Log "Error grabbing uninstall strings: $($_.Exception.Message)" "ERROR"
    }
}

Grab-UninstallStrings

# Detect Manufacturer and Remove Bloatware
function Remove-ManufacturerBloat {
    Try {
        Write-Log "Detecting Manufacturer"
        $details = Get-CimInstance -ClassName Win32_ComputerSystem
        $manufacturer = $details.Manufacturer

        if ($manufacturer -like "*HP*") {
            Write-Log "HP detected"
            # Remove HP bloat
            $UninstallPrograms = @(
                "HP Client Security Manager",
                "HP Notifications",
                "HP Security Update Service",
                "HP System Default Settings",
                "HP Wolf Security",
                "HP Wolf Security Application Support for Sure Sense",
                "HP Wolf Security Application Support for Windows",
                "AD2F1837.HPPCHardwareDiagnosticsWindows",
                "AD2F1837.HPPowerManager",
                "AD2F1837.HPPrivacySettings",
                "AD2F1837.HPQuickDrop",
                "AD2F1837.HPSupportAssistant",
                "AD2F1837.HPSystemInformation",
                "AD2F1837.myHP",
                "RealtekSemiconductorCorp.HPAudioControl",
                "HP Sure Recover",
                "HP Sure Run Module",
                "RealtekSemiconductorCorp.HPAudioControl_2.39.280.0_x64__dt26b99r8h8gj",
                "HP Wolf Security - Console",
                "HP Wolf Security Application Support for Chrome 122.0.6261.139",
                "Windows Driver Package - HP Inc. sselam_4_4_2_453 AntiVirus  (11/01/2022 4.4.2.453)"
            )

            $WhitelistedApps = @()
            if ($customwhitelist) {
                $customWhitelistApps = $customwhitelist -split ","
                foreach ($customwhitelistapp in $customWhitelistApps) {
                    $WhitelistedApps += $customwhitelistapp
                }
            }

            $UninstallPrograms = $UninstallPrograms | Where-Object { $WhitelistedApps -notcontains $_ }
            $HPidentifier = "AD2F1837"
            $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { (($_.DisplayName -in $UninstallPrograms) -or ($_.DisplayName -like "*$HPidentifier*") -and ($_.DisplayName -notin $WhitelistedApps)) }
            $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { (($_.Name -in $UninstallPrograms) -or ($_.Name -like "^$HPidentifier*") -and ($_.Name -notin $WhitelistedApps)) }
            $InstalledPrograms = $allstring | Where-Object { $UninstallPrograms -contains $_.Name }

            # Remove provisioned packages first
            ForEach ($ProvPackage in $ProvisionedPackages) {
                Write-Log "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
                Try {
                    $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
                    Write-Log "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
                } Catch {
                    Write-Log "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"
                }
            }

            # Remove appx packages
            ForEach ($AppxPackage in $InstalledPackages) {
                Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
                Try {
                    $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
                } Catch {
                    Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
                }
            }

            # Remove installed programs
            $InstalledPrograms | ForEach-Object {
                Write-Log "Attempting to uninstall: [$($_.Name)]..."
                $uninstallcommand = $_.String
                Try {
                    if ($uninstallcommand -match "^msiexec*") {
                        $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                        Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
                    } else {
                        start-process $uninstallcommand
                    }
                    Write-Log "Successfully uninstalled: [$($_.Name)]"
                } Catch {
                    Write-Log "Failed to uninstall: [$($_.Name)]"
                }
            }

            # Remove via CIM too
            foreach ($program in $UninstallPrograms) {
                Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
            }

            # Remove HP Documentation if it exists
            if (test-path -Path "C:\Program Files\HP\Documentation\Doc_uninstall.cmd") {
                Start-Process -FilePath "C:\Program Files\HP\Documentation\Doc_uninstall.cmd" -Wait -NoNewWindow
                Write-Log "Removed HP Documentation"
            }

            # Remove HP Connect Optimizer if setup.exe exists
            if (test-path -Path 'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe') {
                invoke-webrequest -uri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/De-Bloat/HPConnOpt.iss" -outfile "C:\Windows\Temp\HPConnOpt.iss"
                &'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe' @('-s', '-f1C:\Windows\Temp\HPConnOpt.iss')
                Write-Log "Removed HP Connect Optimizer"
            }

            # Remove other unnecessary HP components
            if (Test-Path -Path "C:\Program Files (x86)\HP\Shared" -PathType Container) { Remove-Item -Path "C:\Program Files (x86)\HP\Shared" -Recurse -Force }
            if (Test-Path -Path "C:\Program Files (x86)\Online Services" -PathType Container) { Remove-Item -Path "C:\Program Files (x86)\Online Services" -Recurse -Force }
            if (Test-Path -Path "C:\ProgramData\HP\TCO" -PathType Container) { Remove-Item -Path "C:\ProgramData\HP\TCO" -Recurse -Force }
            if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk" -PathType Leaf) { Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk" -Force }
            if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk" -PathType Leaf) { Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk" -Force }
            if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk" -PathType Leaf) { Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk" -Force }

            Write-Log "Removed HP bloat"
        }

        if ($manufacturer -like "*Dell*") {
            Write-Log "Dell detected"
            # Remove Dell bloat
            $UninstallPrograms = @(
                "Dell Optimizer",
                "Dell Power Manager",
                "DellOptimizerUI",
                "Dell SupportAssist OS Recovery",
                "Dell SupportAssist",
                "Dell Optimizer Service",
                "Dell Optimizer Core",
                "DellInc.PartnerPromo",
                "DellInc.DellOptimizer",
                "DellInc.DellCommandUpdate",
                "DellInc.DellPowerManager",
                "DellInc.DellDigitalDelivery",
                "DellInc.DellSupportAssistforPCs",
                "Dell Command | Update",
                "Dell Command | Update for Windows Universal",
                "Dell Command | Update for Windows 10",
                "Dell Command | Power Manager",
                "Dell Digital Delivery Service",
                "Dell Digital Delivery",
                "Dell Peripheral Manager",
                "Dell Power Manager Service",
                "Dell SupportAssist Remediation",
                "SupportAssist Recovery Assistant",
                "Dell SupportAssist OS Recovery Plugin for Dell Update",
                "Dell SupportAssistAgent",
                "Dell Update - SupportAssist Update Plugin",
                "Dell Core Services",
                "Dell Pair",
                "Dell Display Manager 2.0",
                "Dell Display Manager 2.1",
                "Dell Display Manager 2.2"
            )

            $WhitelistedApps = @(
                "WavesAudio.MaxxAudioProforDell2019",
                "Dell - Extension*",
                "Dell, Inc. - Firmware*"
            )

            if ($customwhitelist) {
                $customWhitelistApps = $customwhitelist -split ","
                foreach ($customwhitelistapp in $customWhitelistApps) {
                    $WhitelistedApps += $customwhitelistapp
                }
            }

            $UninstallPrograms = $UninstallPrograms | Where-Object { $WhitelistedApps -notcontains $_ }
            $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { (($_.DisplayName -in $UninstallPrograms) -or ($_.DisplayName -like "*Dell*") -and ($_.DisplayName -notin $WhitelistedApps)) }
            $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { (($_.Name -in $UninstallPrograms) -or ($_.Name -like "*Dell*") -and ($_.Name -notin $WhitelistedApps)) }
            $InstalledPrograms = $allstring | Where-Object { $UninstallPrograms -contains $_.Name }

            # Remove provisioned packages first
            ForEach ($ProvPackage in $ProvisionedPackages) {
                Write-Log "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
                Try {
                    $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
                    Write-Log "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
                } Catch {
                    Write-Log "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"
                }
            }

            # Remove appx packages
            ForEach ($AppxPackage in $InstalledPackages) {
                Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
                Try {
                    $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
                } Catch {
                    Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
                }
            }

            # Remove installed programs
            $InstalledPrograms | ForEach-Object {
                Write-Log "Attempting to uninstall: [$($_.Name)]..."
                $uninstallcommand = $_.String
                Try {
                    if ($uninstallcommand -match "^msiexec*") {
                        $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                        Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
                    } else {
                        start-process $uninstallcommand
                    }
                    Write-Log "Successfully uninstalled: [$($_.Name)]"
                } Catch {
                    Write-Log "Failed to uninstall: [$($_.Name)]"
                }
            }

            # Remove any bundled packages
            ForEach ($AppxPackage in $InstalledPackages) {
                Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
                Try {
                    $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
                    Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
                } Catch {
                    Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
                }
            }

            $ExcludedPrograms = @(
                "Dell Optimizer Core",
                "Dell SupportAssist Remediation",
                "Dell SupportAssist OS Recovery Plugin for Dell Update",
                "Dell Pair",
                "Dell Display Manager 2.0",
                "Dell Display Manager 2.1",
                "Dell Display Manager 2.2",
                "Dell Peripheral Manager"
            )
            $InstalledPrograms2 = $InstalledPrograms | Where-Object { $ExcludedPrograms -notcontains $_.Name }

            # Remove installed programs
            $InstalledPrograms2 | ForEach-Object {
                Write-Log "Attempting to uninstall: [$($_.Name)]..."
                $uninstallcommand = $_.String
                Try {
                    if ($uninstallcommand -match "^msiexec*") {
                        $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                        $uninstallcommand = $uninstallcommand + " /quiet /norestart"
                        $uninstallcommand = $uninstallcommand -replace "/I", "/X "
                        Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
                    } else {
                        start-process $uninstallcommand
                    }
                    Write-Log "Successfully uninstalled: [$($_.Name)]"
                } Catch {
                    Write-Log "Failed to uninstall: [$($_.Name)]"
                }
            }

            # Belt and braces, remove via CIM too
            foreach ($program in $UninstallPrograms) {
                Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
            }

            # Manual Removals
            # Dell Optimizer
            $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Optimizer*Core" } | Select-Object -Property UninstallString
            ForEach ($sa in $dellSA) {
                If ($sa.UninstallString) {
                    Try {
                        cmd.exe /c $sa.UninstallString -silent
                    } Catch {
                        Write-Log "Failed to uninstall Dell Optimizer"
                    }
                }
            }

            # Dell SupportAssist Remediation
            $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist Remediation" } | Select-Object -Property QuietUninstallString
            ForEach ($sa in $dellSA) {
                If ($sa.QuietUninstallString) {
                    Try {
                        cmd.exe /c $sa.QuietUninstallString
                    } Catch {
                        Write-Log "Failed to uninstall Dell SupportAssist Remediation"
                    }
                }
            }

            # Dell SupportAssist OS Recovery Plugin for Dell Update
            $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist OS Recovery Plugin for Dell Update" } | Select-Object -Property QuietUninstallString
            ForEach ($sa in $dellSA) {
                If ($sa.QuietUninstallString) {
                    Try {
                        cmd.exe /c $sa.QuietUninstallString
                    } Catch {
                        Write-Log "Failed to uninstall Dell SupportAssist OS Recovery Plugin for Dell Update"
                    }
                }
            }

            # Dell Display Manager
            $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Display*Manager*" } | Select-Object -Property UninstallString
            ForEach ($sa in $dellSA) {
                If ($sa.UninstallString) {
                    Try {
                        cmd.exe /c $sa.UninstallString /S
                    } Catch {
                        Write-Log "Failed to uninstall Dell Display Manager"
                    }
                }
            }

            # Dell Peripheral Manager
            Try {
                Start-Process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe" /S'
                Write-Log "Uninstalled Dell Peripheral Manager"
            } Catch {
                Write-Log "Failed to uninstall Dell Peripheral Manager"
            }

            # Dell Pair
            Try {
                Start-Process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Pair\Uninstall.exe" /S'
                Write-Log "Uninstalled Dell Pair"
            } Catch {
                Write-Log "Failed to uninstall Dell Pair"
            }
            
            Write-Log "Removed Dell bloat"
        }

        if ($manufacturer -like "*Lenovo*") {
            Write-Log "Lenovo detected"
            # Remove Lenovo bloat
            function UninstallApp {
                param (
                    [string]$appName
                )
                $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*$appName*" }
                foreach ($app in $installedApps) {
                    $uninstallString = $app.UninstallString
                    $displayName = $app.DisplayName
                    Write-Log "Uninstalling: $displayName"
                    Start-Process $uninstallString -ArgumentList "/VERYSILENT" -Wait
                    Write-Log "Uninstalled: $displayName"
                }
            }

            # Stop Running Processes
            $processnames = @(
                "SmartAppearanceSVC.exe",
                "UDClientService.exe",
                "ModuleCoreService.exe",
                "ProtectedModuleHost.exe",
                "*lenovo*",
                "FaceBeautify.exe",
                "McCSPServiceHost.exe",
                "mcapexe.exe",
                "MfeAVSvc.exe",
                "mcshield.exe",
                "Ammbkproc.exe",
                "AIMeetingManager.exe",
                "DADUpdater.exe",
                "CommercialVantage.exe"
            )
            foreach ($process in $processnames) {
                Write-Log "Stopping Process $process"
                Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force
                Write-Log "Process $process Stopped"
            }

            $UninstallPrograms = @(
                "E046963F.AIMeetingManager",
                "E0469640.SmartAppearance",
                "MirametrixInc.GlancebyMirametrix",
                "E046963F.LenovoCompanion",
                "E0469640.LenovoUtility",
                "E0469640.LenovoSmartCommunication",
                "E046963F.LenovoSettingsforEnterprise",
                "E046963F.cameraSettings",
                "4505Fortemedia.FMAPOControl2_2.1.37.0_x64__4pejv7q2gmsnr",
                "ElevocTechnologyCo.Ltd.SmartMicrophoneSettings_1.1.49.0_x64__ttaqwwhyt5s6t"
            )

            if ($customwhitelist) {
                $customWhitelistApps = $customwhitelist -split ","
                $UninstallPrograms = $UninstallPrograms | Where-Object { $customWhitelistApps -notcontains $_ }
            }

            $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { ($_.Name -in $UninstallPrograms) }
            $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { ($_.Name -in $UninstallPrograms) }
            $InstalledPrograms = $allstring | Where-Object { ($_.Name -in $UninstallPrograms) }

            # Remove provisioned packages first
            ForEach ($ProvPackage in $ProvisionedPackages) {
                Write-Log "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
                Try {
                    $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
                    Write-Log "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
                } Catch {
                    Write-Log "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"
                }
            }

            # Remove appx packages
            ForEach ($AppxPackage in $InstalledPackages) {
                Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
                Try {
                    $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
                } Catch {
                    Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
                }
            }

            # Remove any bundled packages
            ForEach ($AppxPackage in $InstalledPackages) {
                Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
                Try {
                    $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
                    Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
                } Catch {
                    Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
                }
            }

            # Remove installed programs
            $InstalledPrograms | ForEach-Object {
                Write-Log "Attempting to uninstall: [$($_.Name)]..."
                $uninstallcommand = $_.String
                Try {
                    if ($uninstallcommand -match "^msiexec*") {
                        $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                        Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
                    } else {
                        start-process $uninstallcommand
                    }
                    Write-Log "Successfully uninstalled: [$($_.Name)]"
                } Catch {
                    Write-Log "Failed to uninstall: [$($_.Name)]"
                }
            }

            # Belt and braces, remove via CIM too
            foreach ($program in $UninstallPrograms) {
                Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
            }

            # Get Lenovo Vantage service uninstall string to uninstall service
            $lvs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -eq "Lenovo Vantage Service"
            if (!([string]::IsNullOrEmpty($lvs.QuietUninstallString))) {
                $uninstall = "cmd /c " + $lvs.QuietUninstallString
                Write-Log $uninstall
                Invoke-Expression $uninstall
            }

            # Uninstall Lenovo Smart
            UninstallApp -appName "Lenovo Smart"

            # Uninstall Ai Meeting Manager Service
            UninstallApp -appName "Ai Meeting Manager"

            # Uninstall ImController service
            $path = "c:\windows\system32\ImController.InfInstaller.exe"
            if (Test-Path $path) {
                Write-Log "ImController.InfInstaller.exe exists"
                $uninstall = "cmd /c " + $path + " -uninstall"
                Write-Log $uninstall
                Invoke-Expression $uninstall
            } else {
                Write-Log "ImController.InfInstaller.exe does not exist"
            }

            # Remove vantage associated registry keys
            Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -Recurse -ErrorAction SilentlyContinue
            Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' -Recurse -ErrorAction SilentlyContinue
            Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Lenovo Vantage' -Recurse -ErrorAction SilentlyContinue

            # Uninstall AI Meeting Manager Service
            $path = 'C:\Program Files\Lenovo\Ai Meeting Manager Service\unins000.exe'
            $params = "/SILENT"
            if (Test-Path -Path $path) {
                Start-Process -FilePath $path -ArgumentList $params -Wait
            }

            # Uninstall Lenovo Vantage
            $pathname = (Get-ChildItem -Path "C:\Program Files (x86)\Lenovo\VantageService").name
            $path = "C:\Program Files (x86)\Lenovo\VantageService\$pathname\Uninstall.exe"
            $params = '/SILENT'
            if (Test-Path -Path $path) {
                Start-Process -FilePath $path -ArgumentList $params -Wait
            }

            # Uninstall Smart Appearance
            $path = 'C:\Program Files\Lenovo\Lenovo Smart Appearance Components\unins000.exe'
            $params = '/SILENT'
            if (Test-Path -Path $path) {
                Try {
                    Start-Process -FilePath $path -ArgumentList $params -Wait
                } Catch {
                    Write-Log "Failed to start the process"
                }
            }

            $lenovowelcome = "c:\program files (x86)\lenovo\lenovowelcome\x86"
            if (Test-Path $lenovowelcome) {
                Set-Location "c:\program files (x86)\lenovo\lenovowelcome\x86"
                $PSScriptRoot = (Get-Item -Path ".\").FullName
                Try {
                    Invoke-Expression -Command .\uninstall.ps1 -ErrorAction SilentlyContinue
                } Catch {
                    Write-Log "Failed to execute uninstall.ps1"
                }
                Write-Log "All applications and associated Lenovo components have been uninstalled."
            }

            $lenovonow = "c:\program files (x86)\lenovo\LenovoNow\x86"
            if (Test-Path $lenovonow) {
                Set-Location "c:\program files (x86)\lenovo\LenovoNow\x86"
                $PSScriptRoot = (Get-Item -Path ".\").FullName
                Try {
                    Invoke-Expression -Command .\uninstall.ps1 -ErrorAction SilentlyContinue
                } Catch {
                    Write-Log "Failed to execute uninstall.ps1"
                }
                Write-Log "All applications and associated Lenovo components have been uninstalled."
            }
        }
    } Catch {
        Write-Log "Error detecting manufacturer or removing bloat: $($_.Exception.Message)" "ERROR"
    }
}

Remove-ManufacturerBloat

# Remove Any other installed crap
function Remove-OtherCrap {
    Try {
        Write-Log "Detecting McAfee"
        $mcafeeinstalled = $false
        $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        foreach ($obj in $InstalledSoftware) {
            $name = $obj.GetValue('DisplayName')
            if ($name -like "*McAfee*") {
                $mcafeeinstalled = $true
            }
        }

        if ($mcafeeinstalled) {
            Write-Log "McAfee detected"
            $McafeeRegex = "McAfee*"
            $RemoveMcafee = $allstring | where { $_.Name -match $McafeeRegex }
            $RemoveMcafee | ForEach-Object {
                Write-Log "Attempting to uninstall: [$($_.Name)]..."
                $uninstallcommand = $_.String
                if ($uninstallcommand -match "^msiexec*") {
                    $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                    Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
                } else {
                    start-process $uninstallcommand
                }
                Write-Log "Successfully uninstalled: [$($_.Name)]"
            }
        }

        $uninstallothercrap = @(
            "McAfee LiveSafe",
            "WildTangent Games"
        )

        if ($customwhitelist) {
            $customWhitelistApps = $customwhitelist -split ","
            foreach ($customwhitelistapp in $customWhitelistApps) {
                $uninstallothercrap = $uninstallothercrap | Where-Object { $customwhitelistapp -notcontains $_ }
            }
        }

        $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { ($_.Name -in $uninstallothercrap) }
        $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { ($_.Name -in $uninstallothercrap) }
        $InstalledPrograms = $allstring | Where-Object { ($_.Name -in $uninstallothercrap) }

        # Remove provisioned packages first
        ForEach ($ProvPackage in $ProvisionedPackages) {
            Write-Log "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
            Try {
                $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
                Write-Log "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
            } Catch {
                Write-Log "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"
            }
        }

        # Remove appx packages
        ForEach ($AppxPackage in $InstalledPackages) {
            Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
            Try {
                $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
            } Catch {
                Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
            }
        }

        # Remove any bundled packages
        ForEach ($AppxPackage in $InstalledPackages) {
            Write-Log "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
            Try {
                $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
                Write-Log "Successfully removed Appx package: [$($AppxPackage.Name)]"
            } Catch {
                Write-Log "Failed to remove Appx package: [$($AppxPackage.Name)]"
            }
        }

        # Remove installed programs
        $InstalledPrograms | ForEach-Object {
            Write-Log "Attempting to uninstall: [$($_.Name)]..."
            $uninstallcommand = $_.String
            Try {
                if ($uninstallcommand -match "^msiexec*") {
                    $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                    Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
                } else {
                    start-process $uninstallcommand
                }
                Write-Log "Successfully uninstalled: [$($_.Name)]"
            } Catch {
                Write-Log "Failed to uninstall: [$($_.Name)]"
            }
        }

        # Belt and braces, remove via CIM too
        foreach ($program in $uninstallothercrap) {
            Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
        }

        # Additional steps for McAfee removal if needed
        if ($mcafeeinstalled) {
            Write-Log "Performing additional steps for McAfee removal"
            $McAfeeFolderPaths = @(
                "C:\Program Files\McAfee",
                "C:\Program Files (x86)\McAfee",
                "C:\ProgramData\McAfee"
            )

            foreach ($path in $McAfeeFolderPaths) {
                if (Test-Path -Path $path) {
                    Write-Log "Removing McAfee folder: $path"
                    Remove-Item -Path $path -Recurse -Force
                }
            }

            $McAfeeRegistryPaths = @(
                "HKLM:\SOFTWARE\McAfee",
                "HKLM:\SOFTWARE\Wow6432Node\McAfee",
                "HKCU:\Software\McAfee"
            )

            foreach ($path in $McAfeeRegistryPaths) {
                if (Test-Path -Path $path) {
                    Write-Log "Removing McAfee registry key: $path"
                    Remove-Item -Path $path -Recurse -Force
                }
            }

            Write-Log "McAfee removal complete"
        }

        Write-Log "Removed other crap"
    } Catch {
        Write-Log "Error removing other installed crap: $_" "ERROR"
    }
}

Remove-OtherCrap

# Complete the process
Try {
    Stop-Transcript
    Write-Host "Transcript stopped."
    Write-Host "De-Bloat process completed."
} Catch {
    Write-Host "Error stopping transcript: $_" "ERROR"
}

# End of Script
Write-Host "Script execution completed."

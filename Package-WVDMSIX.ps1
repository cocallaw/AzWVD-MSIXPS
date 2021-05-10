<#
.DESCRIPTION
Powershell script to perfrom MSIX App Attach functions for WVD
.LINK
https://github.com/cocallaw/AzWVD-MSIXPS
#>

#region variables
$msixmgrURI = "https://aka.ms/msixmgr"
$msixdlpath = "C:\MSIX"
$msixworkingpath = "C:\MSIXappattach"
$msixexepathx64 = "$msixworkingpath\x64\msixmgr.exe"
$msixexepathx86 = "$msixworkingpath\x86\msixmgr.exe"
$msixvhdname = ""
$msixvhdfolder = ""
$msixpackage = ""
#endregion variables

#region functions
function Get-Option {
    Write-Host "What would you like to do?"
    Write-Host "1 - Create MSIX VHD"
    Write-Host "2 - Download MSIX Manager"    
    Write-Host "3 - Install Windows 10 Hyper-V PowerShell"
    Write-Host "4 - Configure Machine for MSIX Packaging"
    Write-Host "8 - Exit"
    $o = Read-Host -Prompt 'Please type the number of the option you would like to perform'
    return ($o.ToString()).Trim()
}

function Get-LatestMSIXMGR {
    Write-Host "Creating File Paths $msixdlpath and $msixworkingpath"
    New-Item -Path $msixdlpath -ItemType Directory -Force
    New-Item -Path $msixworkingpath -ItemType Directory -Force
    try {
        try {
            Start-BitsTransfer -Source $msixmgrURI -Destination "$msixdlpath\MSIXManager.zip"
        }
        catch {
            Invoke-WebRequest -Uri $msixmgrURI -OutFile "$msixdlpath\MSIXManager.zip"
        }
    }
    catch {
        Write-Host "Download Error"
    }
    Write-Host "Downloaded MSIXManager to $msixdlpath"
    Write-Host "Expanding and cleaning up MSIXManager"
    Expand-Archive "$msixdlpath\MSIXManager.zip" -DestinationPath $msixworkingpath -ErrorAction SilentlyContinue
    Remove-Item "$msixdlpath" -Recurse
}

function get-msixpackagepath {
    Add-Type -AssemblyName System.Windows.Forms
    $FB = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
    $null = $FB.ShowDialog()
    return $FB.FileName
}
#endregion functions

#region options
function Invoke-Option {
    param (
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 1)]
        [string]$userSelection
    )

    if ($userSelection -eq "1") {
        #1 - Create MSIX VHD
        if (Get-Module -ListAvailable -Name Hyper-V) {
            Write-Host "Found Hyper-V PowerShell Modules for VHD creation" -BackgroundColor Black -ForegroundColor Green
        } 
        else {
            Write-Host "Hyper-V Powershell Modules are not installed on $env:computername" -BackgroundColor Black -ForegroundColor Yellow
            Write-Host "Unable to create VHD without Hyper-V Powershell Modules" -BackgroundColor Black -ForegroundColor Yellow
            $hv = Read-Host -Prompt "Would you like to enable Hyper-V PowerShell modules on $env:computername ? (y/n)"
            if ($hv.Trim().ToLower() -eq "y") {
                Invoke-Option -userSelection "3"
            }
            elseif ($hv.Trim().ToLower() -eq "n") {
                Invoke-Option -userSelection (Get-Option)
            }
            else {
                Write-Host "Invalid option entered" -ForegroundColor Yellow -BackgroundColor Black
                Invoke-Option -userSelection (Get-Option)
            }
        }

        #Check for MSIXManager Tools
        if (!(Test-Path -Path $msixexepathx64 )) {
            Write-Host "MSIX Manager Tools not found on $env:computername at $msixworkingpath"
            $hv = Read-Host -Prompt "Would you like to download the latest MSIX Manager Tools on $env:computername ? (y/n)"
            if ($hv.Trim().ToLower() -eq "y") {
                Write-Host "Downloading the latest MSIX Manger Tools from $msixmgrURI"
                Get-LatestMSIXMGR     
            }    
            elseif ($hv.Trim().ToLower() -eq "n") {
                Write-Host "MSIX Manager Tools are required to properly package MSIX apps" -BackgroundColor Black -ForegroundColor Yellow
                Write-Host "Exiting packaging, please download latest tooling to proceed further" -BackgroundColor Black -ForegroundColor Yellow
                Invoke-Option -userSelection (Get-Option)
            }
            else {
                Write-Host "Invalid option entered" -ForegroundColor Yellow -BackgroundColor Black
                Invoke-Option -userSelection (Get-Option)
            }
        }

        #Creating VHD Object
        $msixvhdname = Read-Host -Prompt 'Please provide the name for the VHD:'
        $msixvhdfolder = Read-Host -Prompt 'Please provide a folder name for the MSIX to be expaned to on the VHD:'
        Write-Host "Please provide the path to the MSIX package you would like to use:"
        $msixpackage = get-msixpackagepath
        Write-Host "Using the MSIX Package located at - $msixpackage"
        $vs = Read-Host -Prompt "Would you like to create the VHD with the default size of 1024MB ? (y/n)"
        if ($vs.Trim().ToLower() -eq "y") {
            New-VHD -SizeBytes 1024MB -Path "c:\$msixworkingpath\$msixvhdname.vhd" -Dynamic -Confirm:$false
        }
        elseif ($vs.Trim().ToLower() -eq "n") {
            Write-Host "Please proved the storage size that the VHD should be provisioned"
            Write-Host "For Megabytes use MB (e.g. 500MB) and for Gigabytes use GB (e.g 2GB)"
            $s = Read-Host -Prompt "Size:"
            New-VHD -SizeBytes $s.Trim().Replace(" ", "") -Path "c:\$msixworkingpath\$msixvhdname.vhd" -Dynamic -Confirm:$false
        }
        else {
            Write-Host "Invalid option entered" -ForegroundColor Yellow -BackgroundColor Black
            Invoke-Option -userSelection (Get-Option)
        }
        $vhdObject = Mount-VHD "c:\$msixworkingpath\$msixvhdname.vhd" -Passthru
        $disk = Initialize-Disk -Passthru -Number $vhdObject.Number
        $partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber $disk.Number
        Format-Volume -FileSystem NTFS -Confirm:$false -DriveLetter $partition.DriveLetter -Force
        #Expand MSIX Package into VHD 
        .\$msixworkingpath\msixmgr.exe -Unpack -packagePath $msixpackage -destination "d:\$msixvhdfolder" -applyacls
        #Unmount VHD
        Dismount-VHD -path "c:\$msixworkingpath\$msixvhdname.vhd"
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "2") {
        #2 - Download MSIX Manager
        Get-LatestMSIXMGR
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "3") {
        #3 - Install Windows 10 Hyper-V PowerShell
        Write-Host "Installing Hyper-V PowerShell Modules on $env:computername"
        $ihps = Read-Host -Prompt "Please confirm installation og Hyper-V features on $env:computername (y/n)"
        if ($ihps.Trim().ToLower() -eq "y") {
            Enable-WindowsOptionalFeature -Online -FeatureName:Microsoft-Hyper-V -All
            Invoke-Option -userSelection (Get-Option)
        }
        elseif ($ihps.Trim().ToLower() -eq "n") {
            Invoke-Option -userSelection (Get-Option)
        }
        else {
            Write-Host "Invalid option entered" -ForegroundColor Yellow -BackgroundColor Black
            Invoke-Option -userSelection (Get-Option)
        }
    }
    elseif ($userSelection -eq "4") {
        #4 - Configure Machine for MSIX Packaging 
        Write-Host "Configuring $env:computername for MSIX Packaging"
        Write-Host "Configuring registry key AutoDownload for HKLM\Software\Policies\Microsoft\WindowsStore" -BackgroundColor Black -ForegroundColor Yellow
        reg add HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 0 /f
        Write-Host "Update of scheduled task \Microsoft\Windows\WindowsUpdate\Scheduled Start to Disable" -BackgroundColor Black -ForegroundColor Yellow
        Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable
        Write-Host "Configuring registry key PreInstalledAppsEnabled for HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -BackgroundColor Black -ForegroundColor Yellow
        reg add HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
        Write-Host "COnfiguring registry key ContentDeliveryAllowedOverride for HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug" -BackgroundColor Black -ForegroundColor Yellow
        reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug /v ContentDeliveryAllowedOverride /t REG_DWORD /d 0x2 /f
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "5") {
        #5 - Create Self Signed Cert for Testing 

        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "8") {
        #8 - Exit
        break
    }
    else {
        Write-Host "You have selected an invalid option please select again." -ForegroundColor Red -BackgroundColor Black
        Invoke-Option -userSelection (Get-Option)
    }
}
#endregion options

#region main 
Write-Host "Welcome to the MSIX PS Multitool Script"
try {
    Invoke-Option -userSelection (Get-Option)
}
catch {
    Write-Host "Something went wrong" -ForegroundColor Yellow -BackgroundColor Black
    Invoke-Option -userSelection (Get-Option)
}
#endregion main

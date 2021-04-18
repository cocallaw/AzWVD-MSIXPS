#region variables
$msixmgrURI = "https://aka.ms/msixmgr"
$msixdlpath = "C:\MSIX"
$msixworkingpath = "C:\MSIXappattach"
$msixvhdname = ""
$msixvhdfolder = ""
$msixpackage = ""

#endregion variables

#region functions
function Get-Option {
    Write-Host "What would you like to do?"
    Write-Host "1 - Create MSIX VHDX"
    Write-Host "2 - Download MSIX Manager"    
    Write-Host "3 - Install Windows 10 Hyper-V PowerShell"
    Write-Host "4 - Configure Machine for MSIX Packaging"
    Write-Host "8 - Exit"
    $o = Read-Host -Prompt 'Please type the number of the option you would like to perform'
    return ($o.ToString()).Trim()
}

function Invoke-Option {
    param (
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 1)]
        [string]$userSelection
    )
}

function Get-LatestMSIXMGR {
    New-Item -Path $msixdlpath -ItemType Directory -Force
    New-Item -Path $msixworkingpath -ItemType Directory -Force
    try {
        Start-BitsTransfer -Source $msixmgrURI -Destination "$msixdlpath\MSIXManager.zip"
    }
    catch {
        Invoke-WebRequest -Uri $msixmgrURI -OutFile "$msixdlpath\MSIXManager.zip"
    }
    Write-Host "Downloaded MSIXManager to $msixdlpath"
    Write-Host "Expanding and cleaning up MSIXManager"
    Expand-Archive "$WVDSetupFslgxPath\FSLogix_Apps.zip" -DestinationPath "$msixworkingpath" -ErrorAction SilentlyContinue
    Remove-Item "$WVDSetupFslgxPath\FSLogix_Apps.zip" 
}

function get-msixpackagepath {
    Add-Type -AssemblyName System.Windows.Forms
    $FB = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
    $null = $FB.ShowDialog()
    return $FB.FileName
}
#endregion functions

#region options
if ($userSelection -eq "1") {
    #1 - Create MSIX VHDX
    #Check for Modules if not installed request install 

    #Create VHDX
    $msixvhdname = Read-Host -Prompt 'Please provide the name for the VHD:'
    Write-Host "Please provide the path to the MSIX package you would like to use:"
    $msixpackage = get-msixpackagepath
    Write-Host "Using the MSIX Package located at - $msixpackage"
    New-VHD -SizeBytes 1024MB -Path "c:\$msixworkingpath\$msixvhdname.vhd" -Dynamic -Confirm:$false
    $vhdObject = Mount-VHD "c:\$msixworkingpath\$msixvhdname.vhd" -Passthru
    $disk = Initialize-Disk -Passthru -Number $vhdObject.Number
    $partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber $disk.Number
    Format-Volume -FileSystem NTFS -Confirm:$false -DriveLetter $partition.DriveLetter -Force

    #Expand MSIX Package into VHDX 
    msixmgr.exe -Unpack -packagePath $msixpackage -destination "d:\$msixvhdfolder" -applyacls

    #Unmount and Provide details 
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
    Enable-WindowsOptionalFeature -Online -FeatureName:Microsoft-Hyper-V -All
    Invoke-Option -userSelection (Get-Option)
}
elseif ($userSelection -eq "4") {
    #4 - Configure Machine for MSIX Packaging 
    Write-Host "Configuring $env:computername for MSIX Packaging"
    reg add HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 0 /f
    Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable
    reg add HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
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

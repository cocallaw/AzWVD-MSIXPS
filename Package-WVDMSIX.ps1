#region variables
$msixmgrURI = "https://aka.ms/msixmgr"
$msixdlpath = "C:\MSIX"
$msixworkingpath = "C:\MSIXappattach"
#endregion variables


#region functions
function Get-LatestMSIXMGR {
    New-Item -Path $msixdlpath -ItemType Directory -Force
    New-Item -Path $msixworkingpath -ItemType Directory -Force
    Start-BitsTransfer -Source $msixmgrURI -Destination "$msixdlpath\MSIXManager.zip"
    Write-Host "Downloaded MSIXManager to $msixdlpath"
    Write-Host "Expanding and cleaning up MSIXManager"
    Expand-Archive "$WVDSetupFslgxPath\FSLogix_Apps.zip" -DestinationPath "$msixworkingpath" -ErrorAction SilentlyContinue
    Remove-Item "$WVDSetupFslgxPath\FSLogix_Apps.zip"
    
}
#endregion functions
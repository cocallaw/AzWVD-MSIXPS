# WVD MSIX App Attach Multitool Script

The WVD MSIX App Attach Multitool Script provides the ability to perform configuration of you Windows 10 machine being used to perform MSIX packaging, as well as extracting MSIX packages into VHDs.

To run this PowerShell Script on your Windows 10 VM run the command below -

`Invoke-Expression $(Invoke-WebRequest -uri aka.ms/wvdmsixps -UseBasicParsing).Content`
 
or the shorthand version 

`iwr -useb aka.ms/wvdmsixps | iex`

To download a local copy of the latest version of the script run the command below -

 `Invoke-WebRequest -Uri aka.ms/wvdmsixps -OutFile Run-WVDHostSetup.ps1`

![PowerShell Screenshot](/images/wvdmsixpsscreenshot01.png)


### Currently the WVD MSIX App Attach Multitool provides the option to perform the following tasks as of May 10, 2021

- Create MSIX VHD
- Download MSIX Manager 
- Install Windows 10 Hyper-V PowerShell
- Configure Machined for MSIX Packaging

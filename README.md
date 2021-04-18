# AzWVD-MSIXPS

To run this PowerShell Script on your Windows 10 VM run the command below

`Invoke-Expression $(Invoke-WebRequest -uri aka.ms/wvdmsixps -UseBasicParsing).Content`
 
or

`iwr -useb aka.ms/wvdmsixps | iex`
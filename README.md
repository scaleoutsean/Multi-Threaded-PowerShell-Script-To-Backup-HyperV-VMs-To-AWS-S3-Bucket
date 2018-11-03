# Backup your VMs using PowerShell and S3
A multithreaded PowerShell scipt that exports your Hyper-V VMs to a S3 bucket.  

Create a S3 bucket and install AWS Tools for Windows Powershell bofore testing this script.https://aws.amazon.com/powershell/


NOTES :
If you want to backup your VMs using Windows/Hyper-V native tools you have two option :
1- Windows server backup
You can keep them on-prem or use AWS Storage Gateway to keep them off site.

2-VM Export (This script)


Import the valid version for Hyper-V. I have tested this code on Windows 10 accessing Windows Server 2012 running Hyper-V
If you are not sure what version to choose, test the available versions on your machine using the following command in powershell 
Get-Module -Name Hyper-V -ListAvailable

I recommend you create a lifecycle rule to move the files to Amazon Glacier to save money.
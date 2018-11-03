#************************
#Author : Siamak Heshmati
#A multithreaded PowerShell scipt that exports your Hyper-V VMs to a S3 bucket.  
#************************


#I recommend you create a lifecycle rule to move the files to Amazon Glacier to save money.


#NOTES :
#If you want to backup your VMs using Windows/Hyper-V native tools you have two option :
#1- Windows server backup
#You can keep them on-prem or use AWS Storage Gateway to keep them off site.

#2-VM Export (This script)


#Install AWS Tools for Windows Powershell bofore testing this script. https://aws.amazon.com/powershell/


#Import the valid version for Hyper-V. I have tested this code on Windows 10 accessing Windows Server 2012 running Hyper-V
#If you are not sure what version to choose, test the available versions on your machine using the following command in powershell 
#Get-Module -Name Hyper-V -ListAvailable

Import-Module Hyper-V -RequiredVersion 1.1
Enter-PSSession -computername YOUR-HYPERV-HOSTNAME 


#You can also use a for loop to get the VMs that you want to export using GET-VM
#or put your VM names as following :
$VMLIST=@("Server1","Server2","Server3")



$scriptblock = {Param($VMNAME)
        
        #Update the path
        $VMEXPORTPATH="D:\VM_EXPORT" #You can only export your VM's to a local drive not a network drive.

        $vm_names= Get-VM -ComputerName YOUR-HYPERV-HOSTNAME  | select Name

        #Update the path
        $folderPathOnTheServer="\\YOUR-HYPERV-HOSTNAME\d$\VM_EXPORT\" + $VMNAME

        $zippedFileOnTheServer=$folderPathOnTheServer+ ".zip"

        try
        {
            #Remove the folder if exist
            Remove-Item  -Recurse -Force $folderPathOnTheServer -ErrorAction Ignor
 
            #Remove the zip file if exist
            Remove-Item  -Recurse -Force $zippedFileOnTheServer -ErrorAction Ignor
        }
        catch [Exception]
        {
            echo $_.Exception.GetType().FullName, $_.Exception.Message   
            Break
        }


        

        #Connect to the remote Hyper-V
        Get-VM -ComputerName YOUR-HYPERV-HOSTNAME  -Name $VMNAME


        try
        {
             #Export VM to $VMEXPORTPATH
             Export-VM -ComputerName YOUR-HYPERV-HOSTNAME  -Name $VMNAME -Path $VMEXPORTPATH -ErrorAction Stop 
        }
        catch
        {
             echo $_.Exception.GetType().FullName, $_.Exception.Message   
             Break
        }



        #$source = $serverPath + "\" + $VMNAME
        $source = $folderPathOnTheServer

        #$destination = $serverPath + "\" + $VMNAME + ".zip"
        $destination = $zippedFileOnTheServer

        If(Test-path $destination) {Remove-item $destination}
        Add-Type -assembly "system.io.compression.filesystem"

        #Create a zip file
        [io.compression.zipfile]::CreateFromDirectory($Source, $destination) 



        #Upload to S3 
        Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
        Set-AWSCredential -AccessKey YOUR_ACCESS_KEY -SecretKey YOUR_SECRET_KEY -StoreAs YOUR_NAME

        #Get bucket information
        Get-S3Bucket -ProfileName YOUR_NAME 

        Write-S3Object -BucketName YOUR_S3_BUCKET_NAME -File  $zippedFileOnTheServer -ProfileName YOUR_NAME



        try
        {
            #Remove the folder if exist
            Remove-Item  -Recurse -Force $folderPathOnTheServer -ErrorAction Ignor
 
            #Remove the zip file if exist
            Remove-Item  -Recurse -Force $zippedFileOnTheServer -ErrorAction Ignor
        }
        catch [Exception]
        {
            echo $_.Exception.GetType().FullName, $_.Exception.Message   
            Break
        }

}



ForEach($VMNAME in $VMLIST) 
{ 
    $VMNAME
    #By using multi threading we can execute the command for all the VMs in parallel rather than going one by one.
    Start-Job -scriptblock $scriptblock -ArgumentList $VMNAME
}

Get-Job | Wait-Job 
$out = Get-Job | Receive-Job 
$out |export-csv vm.csv
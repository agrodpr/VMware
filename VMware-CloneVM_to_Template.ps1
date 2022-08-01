#Install PowerCLI
Install-Module -Name PowerShellGet -Force
#Get-Module -Name VMware.PowerCLI -ListAvailable 
#Install-Module -Name PowerShellGet -Force
#Install-Module -Name VMware.PowerCLI -Scope AllUsers -Repository PSGallery -Force -AllowClobber

#cd "C:\Users\%username%\Documents\WindowsPowerShell\Modules"
#Get-ChildItem * -Recurse | Unblock-File 
#cd "C:\Program Files\WindowsPowerShell\Modules"
#Get-ChildItem * -Recurse | Unblock-File 
#cd "C:\Windows\system32\WindowsPowerShell\v1.0\Modules"
#Get-ChildItem * -Recurse | Unblock-File
#cd "C:\Program Files (x86)\Microsoft Azure Information Protection\Powershell"
#Get-ChildItem * -Recurse | Unblock-File

#Variables
$TargetVCenter ="vcenter.domain.local"
$TargetESXiCluster = "ESXiClusterName"
$TargetESXiHost = "ESXiServerName.domain.local"
$TargetDatastore = "DataStoreName"
$DiskStorageFormat = "Thin" #EagerZeroedThick, Thick, Thick2GB, Thin, Thin2GB
$TargetNetworkName = "VMNetworkName"
$TargetVMFolder = "Folder_Name"
$SourceVM = "PRODVM" #Name of Production VM
$ClonedVM = "PRODVM_Clone" #Name of ClonevVM
$Template = "PRODVM_Template" #Name of Template
$DeployedVM = "PRODVM_$TodaysDate"
$TodaysDate = Get-Date -UFormat "%Y-%m-%d-%R"

#Connect to vCenter
Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction warn
Connect-VIServer -Server $TargetVCenter

#Clone a VM to ClonedVM
New-VM -Name $ClonedVM -VM $SourceVM -VMHost $TargetESXiHost -Datastore $TargetDatastore -DiskStorageFormat $DiskStorageFormat -Location $TargetVMFolder -RunAsync -Notes "Created on $TodaysDate"

#Convert ClonedVM to Template
Get-VM -Name $ClonedVM | Set-VM -ToTemplate -Confirm:$false -RunAsync
#New-Template -VM $ClonedVM -Name $ClonedVM -Datastore 'VMDatastore' -Location 'VMLocation'

#Confirm Template is created
Get-Template

#DeployVM from Template
Set-Template -Template $ClonedVM -ToVM -RunAsync

#DeleteCloneVM
Get-VM -Name $ClonedVM | Remove-VM -DeletePermanently -Confirm:$false

#Start Cloned VM
Get-VM -Name $DeployedVM| Start-VM -Confirm:$False

#DeployVM per CSV List:
$vms = Import-Csv -Path D:\Scripts\VMware\Deploy_VMs\Deploy_VMs.csv
foreach ($vm in $vms) {
Write-Warning "Creating $($vm.Name) in $($vm.cluster)"
New-VM -Name $vm.Name -Datastore $vm.Datastore -Template $vm.Template  -ResourcePool $vm.Cluster
}

Foreach ($vmtemplate in (Get-Template Win*))
{
Set-Template -Template $vmtemplate -ToVM
}
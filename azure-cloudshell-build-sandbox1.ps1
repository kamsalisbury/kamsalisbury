# Variables
$resourceGroupName = 'KSS2'
$location = 'northcentralus'
$tags = @{"Project"="Dev"; "CostCenter"="KSS"}
$vmName1 = "Apollo"

Write-Host "Creating Resource Group..."
$rg = @{
    Name = $resourceGroupName
    Location = $location
    Tags = $tags
}
New-AzResourceGroup @rg -Verbose

# Set VM virtual network
Write-Host "Creating Virtual Network and Subnet..."
$networkName = "kssNet"
$vnetAddressPrefix = "10.188.0.0/16"
$subnetName = "vmSubnet"
$subnetAddressPrefix = "10.188.0.0/24"
$nicName = $vmName1
$singleSubnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
$vnet = New-AzVirtualNetwork -Name $networkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $singleSubnet
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id
# https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-12.3.0#example-3-create-a-vm-from-a-marketplace-image-without-a-public-ip
# Set VM Variables
# Reference: List VMimage SKUs https://learn.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
# Get-AzVMImage -Location $location -PublisherName Redhat -Offer RHEL -Sku 9_4 | Select Version
# Set the Marketplace image
$publisherName = "Redhat"
$offerName = "RHEL"
$skuName = "9_4"
$version = "9.4.2024081415"
$vmSize = "Standard_B1s"
Write-Host "Creating VM configuration..."
$virtualMachine = New-AzVMConfig -VMName $vmName1 -VMSize $vmSize
# Reference https://learn.microsoft.com/en-us/powershell/module/az.compute/set-azvmoperatingsystem?view=azps-12.2.0
Set-AzVMOperatingSystem -VM $virtualMachine -Linux -ComputerName $vmName1 -Credential (Get-Credential) -DisablePasswordAuthentication
Set-AzVMBootDiagnostic -VM $virtualMachine -Disable
Add-AzVMNetworkInterface -VM $virtualMachine -Id $nic.Id
Set-AzVMSourceImage -VM $virtualMachine -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version latest
# Create the VM
Write-Host "Creating the VM..."
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachine -SshKeyName 'ed25519' -GenerateSshKey -NetworkInterfaceDeleteOption 'Delete' -Verbose
#Set-AzVMOperatingSystem -VM $virtualMachine -ProvisionVMAgent -PatchMode "AutomaticByPlatform" -EnableHotpatching
# This script automates building a Resource Group, Private Network, associated Subnet, and VM with SSH login and without a public IP. 
Write-Host "This script automates building a Resource Group, Private Network, associated Subnet, and VM with SSH login and without a public IP."

# Variables
$resourceGroupName = 'KSS4'
$location = 'northcentralus'
$tags = @{"Project"="Dev"; "CostCenter"="KSS"}
$vmName1 = "vm-" + (New-Guid).Guid.Substring(0, 8)

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
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachine -SshKeyName 'ed25519' -GenerateSshKey -Verbose
#Set-AzVMOperatingSystem -VM $virtualMachine -ProvisionVMAgent -PatchMode "AutomaticByPlatform" -EnableHotpatching
Write-Host "CAUTION: The VM's only copy of the SSH PRIVATE KEY is saved in this Cloud Shell! Store the key in an Azure Key Vault or download it immediately."
# Create Key Vault and store SSH Private Key
Write-Host "Creating the Key Vault..."
$vaultName = "kss-vm-access"
New-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $vaultName -Location $location
Set-AzKeyVaultAccessPolicy -VaultName $vaultName -UserPrincipalName 'kam.salisbury.it@icloud.com' -PermissionsToSecrets Get,List,Set
$secretName = $vmName1
$sshPrivateKeyPath = $vm.OSProfile.LinuxConfiguration.Ssh.PublicKeys[0].Path -replace "\.pub$", ""
$sshPrivateKey = Get-Content -Path $sshPrivateKeyPath -Raw
Set-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue (ConvertTo-SecureString $sshPrivateKey -AsPlainText -Force)
Write-Host "VM Ready! Connect with Bastion Host and Azure Key Vault stored key."
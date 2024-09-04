# Variables
$resourceGroupName = 'KSS3'
$location = 'northcentralus'
$tags = @{"Project"="Dev"; "CostCenter"="KSS"}
$vnetName = 'vnet-1'
$addrPre = '10.0.0.0/16'
$subnetName1 = 'Internal'
$subnet1Prefix = '10.177.1.0/24'
$subnetName2 = 'External'
$subnet2Prefix = '10.177.2.0/24'
#$bastionName = "KSS-Bastion"
#$bastionSubnetName = "kssInternal"
#$bastionAddressPrefix = "10.0.1.0/24"
$VM1 = "Apollo"
$VM2 = "Athena"

Write-Host "Creating Resource Group..."
$rg = @{
    Name = $resourceGroupName
    Location = $location
    Tags = $tags
}
New-AzResourceGroup @rg -Verbose
Start-Sleep -Seconds 15

Write-Host "Creating Virtual Network..."
$vnet = @{
    Name = $vnetName
    ResourceGroupName = $resourceGroupName
    Location = $location
    AddressPrefix = $addrPre
}
$virtualNetwork = New-AzVirtualNetwork @vnet -Verbose

Write-Host "Creating Virtual Network Subnets..."
$subnet1 = @{
    Name = $subnetName1
    VirtualNetwork = $virtualNetwork
    AddressPrefix = $subnet1Prefix
}
$subnetConfig1 = Add-AzVirtualNetworkSubnetConfig @subnet1 -Verbose

$subnet2 = @{
    Name = $subnetName2
    VirtualNetwork = $virtualNetwork
    AddressPrefix = $subnet2Prefix
}
$subnetConfig2 = Add-AzVirtualNetworkSubnetConfig @subnet2 -Verbose

# ISSUE: Currently, New-AzBastion does not support the Developer Sku.
#Write-Host "Creating Bastion Host..."
#New-AzBastion -ResourceGroupName $resourceGroupName -Name $bastionName -VirtualNetworkName $virtualNetwork.Name -Location $location -Sku "Developer"

# New-AzVm -ResourceGroupName $resourceGroupName -Name $VM1 -Location $location -Image 'MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest' -VirtualNetworkName $virtualNetwork.Name -SubnetName $subnetName1 -SecurityGroupName 'myNetworkSecurityGroup' -PublicIpAddressName 'myPublicIpAddress' -OpenPorts 80,3389


$VMLocalAdminUser = "LocalAdminUser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString -String "****" -AsPlainText -Force
$LocationName = "eastus2"
$ResourceGroupName = "MyResourceGroup"
$ComputerName = "MyVM"
$VMName = "MyVM"
$VMSize = "Standard_DS3"

$NetworkName = "MyNet"
$NICName = "MyNIC"
$SubnetName = "MySubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"

$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-datacenter-azure-edition-core' -Version latest

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose
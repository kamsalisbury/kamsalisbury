# Variables
$rgName = 'KSS3'
$location = 'northcentralus'
$tags = @{"Project"="Dev"; "CostCenter"="KSS"}
$vnetName = 'vnet-1'
$addrPre = '10.0.0.0/16'
$subnetName1 = 'Internal'
$subnet1Pre = '10.177.1.0/24'
$subnetName2 = 'External'
$subnet2Pre = '10.177.2.0/24'
$bastionName = "KSS-Bastion"
$bastionSubnetName = "kssInternal"
$bastionAddressPrefix = "10.0.1.0/24"

Write-Host "Creating Resource Group..."
$rg = @{
    Name = $rgName
    Location = $location
    Tags = $tags
}
New-AzResourceGroup @rg -Verbose
Start-Sleep -Seconds 15

Write-Host "Creating Virtual Network..."
$vnet = @{
    Name = $vnetName
    ResourceGroupName = $rgName
    Location = $location
    AddressPrefix = $addrPre
}
$virtualNetwork = New-AzVirtualNetwork @vnet -Verbose

Write-Host "Creating Virtual Network Subnets..."
$subnet1 = @{
    Name = $subnetName1
    VirtualNetwork = $virtualNetwork
    AddressPrefix = $subnet1Pre
}
$subnetConfig1 = Add-AzVirtualNetworkSubnetConfig @subnet1 -Verbose

$subnet2 = @{
    Name = $subnetName2
    VirtualNetwork = $virtualNetwork
    AddressPrefix = $subnet2Pre
}
$subnetConfig2 = Add-AzVirtualNetworkSubnetConfig @subnet2 -Verbose

# ISSUE: Currently, New-AzBastion does not support the Developer Sku.
#Write-Host "Creating Bastion Host..."
#New-AzBastion -ResourceGroupName $rgName -Name $bastionName -VirtualNetworkName $virtualNetwork.Name -Location $location -Sku "Developer"

# AZVnetGraph
A powershell module to visualize vnets cross subscription

## Usage
```
$tenantId = ""
Install-Module -Name AzVnetGraph 
connect-azaccount -tenantId $tenantId
get-azvnetgraph -TenantId $tenantId
```

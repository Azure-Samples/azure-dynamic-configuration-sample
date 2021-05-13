<#
.SYNOPSIS 
    This Automation runbook integrates with Azure event grid subscriptions to get notified when a 
    write command is performed against an Azure Managed Disk.
    The runbook updates the disk with DenyAll in network access policy property.
    
.DESCRIPTION
    This Automation runbook integrates with Azure event grid subscriptions to get notified when a 
    write command is performed against an Azure Managed Disk.
    The runbook updates the disk with DenyAll in network access policy property.
    A RunAs account in the Automation account is required for this runbook.

.PARAMETER WebhookData
    Optional. The information about the write event that is sent to this runbook from Azure Event grid.

.NOTES
    AUTHOR: 
    LASTEDIT: 
#>
 
Param(
    [parameter (Mandatory=$false)]
    [object] $WebhookData
)

$RequestBody = $WebhookData.RequestBody | ConvertFrom-Json
$Data = $RequestBody.data

if($Data.operationName -match "Microsoft.Compute/disks/write" -and $Data.status -match "Succeeded")
{
    # Authenticate to Azure
    $ServicePrincipalConnection = Get-AutomationConnection -Name "RunAsConnection"

    # Get Credentials
    $CertPassword = ConvertTo-SecureString $ServicePrincipalConnection.ClientKey -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList ($ServicePrincipalConnection.ApplicationId,$CertPassword)

    Connect-AzAccount `
        -ServicePrincipal `
        -Tenant $ServicePrincipalConnection.TenantID `
        -Credential $Credentials

    # Set subscription to work against
    Set-AzContext -SubscriptionID $ServicePrincipalConnection.SubscriptionId | Write-Verbose
   
    # Get resource group and disk name
    $Resources = $Data.resourceUri.Split('/')
    $VMResourceGroup = $Resources[4]
    $DiskName = $Resources[8]

    $disk = Get-AzDisk -ResourceGroupName $VMResourceGroup -DiskName $DiskName;

    if ( "DenyAll" -ne $disk.NetworkAccessPolicy) {
        New-AzDiskUpdateConfig -NetworkAccessPolicy 'DenyAll' | Update-AzDisk -ResourceGroupName $VMResourceGroup -DiskName $DiskName;
    }
}
else
{
    Write-Error "Could not find Disk write event"
}

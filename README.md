# Configure provisioning resources by using Event Grid and Automation

The regular way to update Azure resources is by running a command or using Azure portal. The implementation of a policy (force to update the property’s value based on its state) is not supported out of the box. The solution proposed here, includes an event-driven pattern with Automation and Event Grid to configure Azure resources’ properties based on the resource group’s event triggers and the code to set it up. The approach is using Azure services only, not other resources such as custodian.

## Features

This project provides the following features:

* Base package: includes ARM template, PowerShell Runbook script, PowerShell script. This is used to setup Azure Automation, Runbook to configure Azure resources by running  commands from Automation Runbook.
* Triggered package: ARM template to setup Event Grid system Topic on a resource group and configure with Automation Runbook WebHook for triggering.

## Getting Started

### Prerequisites

- An active Azure Subscription
- Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Install [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.9.0)
- Create a service principal to manipulate Azure resources from Azure Automation. You can use az cli command to create 
     ```
      az ad sp create-for-rbac --name sp_name
     ```

## Demo

### Dynamic Managed Disk Configuration
In this sample, we will set a configuration to deny import/export access for Azure managed disks which are provisioned as AKS persistent volumes (PV) or a new disk in new virtual machine provisioned in a VMSS definition.

This value is configured in the networkAccessPolicy of "Microsoft.Compute/disks" resources, but it is not supported in the storageProfile of virtual machine ARM template. If you want to restrict this property while deploying a new Azure Virtual Machine, you can’t configure it at the same time when provisioning the new VM, you must choose from the options below:

To run the sample, follow these steps:

1. Clone this repository
2. Update the parameters' value in arm-deployment/*.parameters.json files
3. Deploy Azure resources (base package):
  - Configure the values below in bash script
    ```
    # set automation resource group name
    automation_rg=automationrg
    
    # set Azure region, "southeastasia" as an example
    azure_region=southeastasia
    ```
  - run az commands to setup the resources
    ```
    # create the resource group to deploy the automation.
    az group create -n $automation_rg --location $azure_region

    # deploy the automation by using az cli
    az deployment group create --name deployment-name --resource-group $automation_rg --template-file arm-deployment/automation.json --parameters arm-deployment/automation.parameters.json --parameters ApplicationId=[replace_with_sp_appid] ClientKey=[replace_with_sp_password]
    ```
  - Deploy Automation Runbook with PowerShell script
    ```
    ./scripts/DeployAutomationRunbook.ps1 -resourceGroupName [Replace_with_ResourceGroup_Name] -automationAccountName [Replace_with_Automation_Account_Name] -scriptPath scripts/ConfigureDiskAutomationRunbook.ps1 -runbookName “RunbookName”
    ```
4. Deploy ARM template to monitor a specific resource group which will be triggered its events to Azure Automation. This needs to be deployed for each resource group.
   ```
    az deployment group create --name automation-eventgrid-monitoring --resource-group [replace_with_triggered_resource_group_name] --template-file arm-deployment/disk-eventgrid.json --parameters arm-deployment/disk-eventgrid.parameters.json --parameters webhookUri=$webhookUri
   ```
5. For the demonstration, you use Azure portal to create a managed disk in the appropriate resource group (step 4). As soon as it is created successfully, check Networking setting to see that it is configured as "Deny All".

## Resources

- Link to supporting information
- Link to similar sample
- ...

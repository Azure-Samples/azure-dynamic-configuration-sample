[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $resourceGroupName,
    [Parameter(Mandatory = $true)]
    [String]
    $automationAccountName,
    [Parameter(Mandatory = $true)]
    [String]
    $scriptPath,
    [Parameter(Mandatory = $true)]
    [String]
    $runbookName
)

$importParams = @{
    Path = $scriptPath
    ResourceGroupName = $resourceGroupName
    AutomationAccountName = $automationAccountName
    Type = 'PowerShell'
    Name = $runbookName
}

Import-AzAutomationRunbook @importParams -Force -Published

# Create WebHook
$webhook = Get-AzAutomationWebhook -Name $runbookName -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue

if ( $null -eq $webhook) {
    Write-Output 'create webhook if it doesn''t exist'

    $start = [DateTime]::UtcNow
    $webhookParams = @{
        ResourceGroupName = $resourceGroupName
        AutomationAccountName = $automationAccountName
        Name = $runbookName
        IsEnabled = $True
        RunbookName = $runbookName
        ExpiryTime = $start.AddYears(1)
    }
    $webhook = New-AzAutomationWebhook @webhookParams -Force
}

Write-Output $webhook.WebhookURI

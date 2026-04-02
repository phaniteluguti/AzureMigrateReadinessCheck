# Azure Migrate Readiness Check - Command Examples

## Interactive Mode Examples

### Basic Interactive Run
```powershell
# Prompts for all options
.\AzureMigrateApplianceReadinessCheck.ps1
```

### Interactive with Some Parameters Pre-set
```powershell
# Pre-set migration type, still prompt for others
.\AzureMigrateApplianceReadinessCheck.ps1 -MigrationApproach Agentless
```

---

## Automated/Parameter Mode Examples

### VMware Agentless Migration
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -EndpointType Public `
    -AuthMethod DeviceCodeFlow `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG"
```

### VMware with Government Cloud
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -CloudType Government `
    -AuthMethod DeviceCodeFlow
```

### VMware with Custom Paths
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -LogPath "C:\AzureMigrate\Logs\Validation.log" `
    -ReportPath "C:\AzureMigrate\Reports\ReadinessReport.html"
```

### Hyper-V Agentless Migration
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType HyperV `
    -EndpointType Public `
    -AuthMethod DeviceCodeFlow
```

### Physical Servers with CSV
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach AgentBased `
    -DiscoveryType Physical `
    -PhysicalServersCSV "C:\Servers\PhysicalServers.csv" `
    -AuthMethod DeviceCodeFlow `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "MigrationRG"
```

### Physical Servers - Interactive CSV Prompt
```powershell
# Prompts for CSV path during execution
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach AgentBased `
    -DiscoveryType Physical
```

---

## Private Endpoints Examples

### VMware with Private Endpoints
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -EndpointType Private `
    -AuthMethod DeviceCodeFlow
```

### Hyper-V with Private Endpoints
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType HyperV `
    -EndpointType Private `
    -AuthMethod EntraIDApp
```

---

## Entra ID App Registration Examples

### VMware with Entra ID App
```powershell
# Assumes registry and certificate are already configured
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -AuthMethod EntraIDApp `
    -InteractiveMode $false `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG"
```

### Physical with Entra ID App
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach AgentBased `
    -DiscoveryType Physical `
    -PhysicalServersCSV ".\servers.csv" `
    -AuthMethod EntraIDApp `
    -SubscriptionId "your-subscription-id"
```

---

## Custom Log and Report Paths

### Specify Custom Paths
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -LogPath "C:\AzureMigrate\Logs\Validation.log" `
    -ReportPath "C:\AzureMigrate\Reports\ReadinessReport.html"
```

### Network Share for Reports (Team Access)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -ReportPath "\\fileserver\MigrationReports\Appliance_$(Get-Date -Format 'yyyyMMdd').html"
```

---

## Advanced Scenarios

### Complete Validation - All Options
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -EndpointType Public `
    -CloudType Public `
    -AuthMethod DeviceCodeFlow `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG" `
    -LogPath "C:\Logs\AzureMigrate.log" `
    -ReportPath "C:\Reports\Readiness.html"
```

### Scheduled Validation Task
```powershell
# For weekly validation checks
$action = New-ScheduledTaskAction `
    -Execute 'PowerShell.exe' `
    -Argument "-File C:\Scripts\AzureMigrateApplianceReadinessCheck.ps1 -InteractiveMode `$false -MigrationApproach Agentless -DiscoveryType VMware -AuthMethod EntraIDApp"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8am

Register-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -TaskName "AzureMigrateReadinessCheck" `
    -Description "Weekly Azure Migrate appliance readiness validation"
```

### Multiple Environments Validation
```powershell
# Production environment
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -SubscriptionId "prod-sub-id" `
    -ResourceGroupName "Prod-AzureMigrate" `
    -ReportPath ".\Reports\Prod_Validation.html"

# Test environment
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -SubscriptionId "test-sub-id" `
    -ResourceGroupName "Test-AzureMigrate" `
    -ReportPath ".\Reports\Test_Validation.html"
```

---

## Troubleshooting Mode

### Skip Authentication (Test Prerequisites Only)
```powershell
# Note: Script doesn't have this feature yet, but would be useful
# This is a conceptual example for future enhancement
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -SkipAuthentication $true `
    -SkipRBAC $true
```

### Verbose Logging
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 -Verbose
```

---

## CSV File Format Examples

### Simple Physical Servers CSV
```csv
hostname,ip
webserver1,192.168.1.10
appserver1,192.168.1.11
dbserver1,192.168.1.12
```

### Physical Servers with Different Subnets
```csv
hostname,ip
web01,10.10.1.10
web02,10.10.1.11
app01,10.20.1.10
app02,10.20.1.11
db01,10.30.1.10
db02,10.30.1.11
```

### Large Environment (100+ Servers)
```powershell
# Generate CSV from Active Directory
Get-ADComputer -Filter {OperatingSystem -like "*Server*"} -Properties DNSHostName, IPv4Address | 
    Select-Object @{N='hostname';E={$_.DNSHostName}}, @{N='ip';E={$_.IPv4Address}} |
    Export-Csv -Path ".\AllServers.csv" -NoTypeInformation

# Run validation with generated CSV
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach AgentBased `
    -DiscoveryType Physical `
    -PhysicalServersCSV ".\AllServers.csv"
```

---

## Integration Examples

### PowerShell Script Wrapper
```powershell
# Wrapper script for standardized deployment
$config = @{
    MigrationApproach = "Agentless"
    DiscoveryType = "VMware"
    SubscriptionId = (Get-AzContext).Subscription.Id
    ResourceGroupName = "AzureMigrate-Prod"
}

.\AzureMigrateApplianceReadinessCheck.ps1 @config

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host "Validation successful - proceeding with appliance deployment" -ForegroundColor Green
    # Continue with deployment automation
} else {
    Write-Host "Validation failed - review report before proceeding" -ForegroundColor Red
    exit 1
}
```

### Azure DevOps Pipeline
```yaml
# azure-pipelines.yml example
steps:
- task: AzurePowerShell@5
  displayName: 'Azure Migrate Readiness Check'
  inputs:
    azureSubscription: 'Azure-Production'
    ScriptType: 'FilePath'
    ScriptPath: 'scripts/AzureMigrateApplianceReadinessCheck.ps1'
    ScriptArguments: >
      -InteractiveMode $false
      -MigrationApproach Agentless
      -DiscoveryType VMware
      -AuthMethod EntraIDApp
      -SubscriptionId $(subscriptionId)
      -ResourceGroupName $(resourceGroupName)
    azurePowerShellVersion: 'LatestVersion'
    
- task: PublishBuildArtifacts@1
  displayName: 'Publish Validation Report'
  inputs:
    PathtoPublish: '$(Build.SourcesDirectory)/*.html'
    ArtifactName: 'ValidationReports'
```

---

## Quick Reference Table

| Scenario | Migration Approach | Discovery Type | Special Parameters |
|----------|-------------------|----------------|-------------------|
| VMware vCenter | Agentless | VMware | None |
| Hyper-V Hosts | Agentless | HyperV | None |
| Physical Servers | AgentBased | Physical | PhysicalServersCSV |
| Government Cloud | Any | Any | CloudType Government |
| Private Link | Any | Any | EndpointType Private |
| Service Principal | Any | Any | AuthMethod EntraIDApp |

> **Note:** Software Inventory, SQL Discovery, Web App Discovery, and Dependency Analysis
> are post-discovery features configured in the appliance configuration manager after setup.
> They are validated by the appliance itself and are not part of this pre-setup script.

---

**Copy and paste any example above to get started quickly!** 🚀

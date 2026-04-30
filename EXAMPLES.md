# Azure Migrate Readiness Check - Command Examples

## Interactive Mode Examples

### Basic Interactive Run
```powershell
# Prompts for all options: source environment, migration approach, endpoint type, URL test mode, region
.\AzureMigrateApplianceReadinessCheck.ps1
```

### Interactive with Some Parameters Pre-set
```powershell
# Pre-set source and URL mode, still prompt for others
.\AzureMigrateApplianceReadinessCheck.ps1 -DiscoveryType VMware -UrlTestMode Wildcard
```

---

## URL Testing Mode Examples

### Wildcard Mode (DNS + HTTP Verification)
```powershell
# Generic wildcard domain verification - no CSV needed
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -EndpointType Public `
    -UrlTestMode Wildcard `
    -CloudType Public
```

### Absolute Mode (Region-Specific URLs from CSV)
```powershell
# Test exact URLs for East Asia region
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -EndpointType Public `
    -UrlTestMode Absolute `
    -AzureRegion EA
```

### Absolute Mode with Custom CSV Path
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType HyperV `
    -UrlTestMode Absolute `
    -AzureRegion WE `
    -CsvPath "C:\Data\MigrateAppliance_ListofURLs_v3.0_combined.csv"
```

### Absolute Mode - Physical Servers in West US 2
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType Physical `
    -EndpointType Public `
    -UrlTestMode Absolute `
    -AzureRegion WUS2 `
    -PhysicalServersCSV ".\servers.csv" `
    -AuthMethod DeviceCodeFlow
```

---

## Automated/Parameter Mode Examples

### VMware Agentless Migration (Wildcard)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -EndpointType Public `
    -UrlTestMode Wildcard `
    -AuthMethod DeviceCodeFlow `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG"
```

### VMware with Government Cloud (Wildcard)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -UrlTestMode Wildcard `
    -CloudType Government `
    -AuthMethod DeviceCodeFlow
```

### VMware with Absolute URLs (East Asia)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -UrlTestMode Absolute `
    -AzureRegion EA `
    -AuthMethod DeviceCodeFlow
```

### VMware with Custom Paths
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -LogPath "C:\AzureMigrate\Logs\Validation.log" `
    -ReportPath "C:\AzureMigrate\Reports\ReadinessReport.html"
```

### Hyper-V Agentless Migration
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType HyperV `
    -EndpointType Public `
    -UrlTestMode Wildcard `
    -AuthMethod DeviceCodeFlow
```

### Physical Servers with CSV (Absolute URLs)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType Physical `
    -UrlTestMode Absolute `
    -AzureRegion WE `
    -PhysicalServersCSV "C:\Servers\PhysicalServers.csv" `
    -AuthMethod DeviceCodeFlow `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "MigrationRG"
```

### Physical Servers - Interactive CSV Prompt
```powershell
# Prompts for CSV path during execution
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType Physical
```

---

## Azure Migrate Project Region Validation Examples

### Validate Region in Non-Interactive Mode
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -UrlTestMode Wildcard `
    -ProjectRegion "eastus"
# Validates that East US supports Azure Migrate project creation
```

### Interactive Region Selection
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1
# During interactive flow, you'll see a numbered list of supported regions
# filtered by your cloud type (Public or Government)
```

---

## Source Infrastructure Connectivity Examples

### VMware Agentless - vCenter + ESXi via CSV (Non-Interactive)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -UrlTestMode Wildcard `
    -VCenterServersCsv ".\VCenterExample.csv" `
    -AuthMethod DeviceCodeFlow
```
> CSV format (`hostname,ip,type`): vCenter gets TCP 443 test; ESXi hosts get TCP 443 + 902

### VMware AgentBased - vCenter Only via CSV
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach AgentBased `
    -UrlTestMode Absolute `
    -AzureRegion EA `
    -VCenterServersCsv ".\VCenterExample.csv" `
    -AuthMethod DeviceCodeFlow
```
> AgentBased: only vCenter entries tested on TCP 443 (ESXi rows are tested on 443 only, no 902)

### Hyper-V Hosts via CSV (Non-Interactive)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType HyperV `
    -UrlTestMode Wildcard `
    -HyperVHostsCsv ".\HyperVHostsExample.csv" `
    -AuthMethod DeviceCodeFlow
```
> CSV format (`hostname,ip,port`): each host tested on specified WinRM port (5985 or 5986)

### Physical Servers with OS Column (Targeted Port Testing)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType Physical `
    -UrlTestMode Absolute `
    -AzureRegion WE `
    -PhysicalServersCSV ".\PhysicalServersExample.csv" `
    -AuthMethod DeviceCodeFlow
```
> CSV format (`hostname,ip,os`): Windows servers get WinRM 5985/5986, Linux servers get SSH 22

### Interactive Mode - Source Connectivity Prompt
```powershell
# During interactive run, the script will ask:
# "Would you like to test connectivity to your source infrastructure? (Y/N)"
# If Y: prompts for target addresses inline or via CSV
.\AzureMigrateApplianceReadinessCheck.ps1 -DiscoveryType VMware -MigrationApproach Agentless
```

---

## Private Endpoints Examples

### VMware with Private Endpoints
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -EndpointType Private `
    -AuthMethod DeviceCodeFlow
```

### Hyper-V with Private Endpoints
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
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
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -AuthMethod EntraIDApp `
    -InteractiveMode $false `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG"
```

### Physical with Entra ID App
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType Physical `
    -UrlTestMode Absolute `
    -AzureRegion NE `
    -PhysicalServersCSV ".\servers.csv" `
    -AuthMethod EntraIDApp `
    -SubscriptionId "your-subscription-id"
```

---

## Custom Log and Report Paths

### Specify Custom Paths
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -LogPath "C:\AzureMigrate\Logs\Validation.log" `
    -ReportPath "C:\AzureMigrate\Reports\ReadinessReport.html"
```

### Network Share for Reports (Team Access)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -ReportPath "\\fileserver\MigrationReports\Appliance_$(Get-Date -Format 'yyyyMMdd').html"
```

---

## Advanced Scenarios

### Complete Validation - All Options (Wildcard)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -EndpointType Public `
    -UrlTestMode Wildcard `
    -CloudType Public `
    -AuthMethod DeviceCodeFlow `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG" `
    -LogPath "C:\Logs\AzureMigrate.log" `
    -ReportPath "C:\Reports\Readiness.html"
```

### Complete Validation - All Options (Absolute)
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -EndpointType Public `
    -UrlTestMode Absolute `
    -AzureRegion EA `
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
    -Argument "-File C:\Scripts\AzureMigrateApplianceReadinessCheck.ps1 -InteractiveMode `$false -DiscoveryType VMware -MigrationApproach Agentless -UrlTestMode Wildcard -AuthMethod EntraIDApp"

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
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -UrlTestMode Absolute `
    -AzureRegion EA `
    -SubscriptionId "prod-sub-id" `
    -ResourceGroupName "Prod-AzureMigrate" `
    -ReportPath ".\Reports\Prod_Validation.html"

# Test environment
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -InteractiveMode $false `
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
    -UrlTestMode Absolute `
    -AzureRegion WE `
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
    -DiscoveryType VMware `
    -MigrationApproach Agentless `
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
    -DiscoveryType Physical `
    -UrlTestMode Absolute `
    -AzureRegion WE `
    -PhysicalServersCSV ".\AllServers.csv"
```

---

## Integration Examples

### PowerShell Script Wrapper
```powershell
# Wrapper script for standardized deployment
$config = @{
    DiscoveryType = "VMware"
    MigrationApproach = "Agentless"
    UrlTestMode = "Absolute"
    AzureRegion = "EA"
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
      -DiscoveryType VMware
      -MigrationApproach Agentless
      -UrlTestMode Absolute
      -AzureRegion EA
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

| Scenario | Discovery Type | Migration Approach | Special Parameters |
|----------|---------------|-------------------|-------------------|
| VMware vCenter | VMware | Agentless | None |
| VMware Agent-Based | VMware | AgentBased | None |
| Hyper-V Hosts | HyperV | (auto: Agentless) | None |
| Physical Servers | Physical | (auto: AgentBased) | PhysicalServersCSV |
| Absolute URLs | Any | Any | UrlTestMode Absolute, AzureRegion |
| Government Cloud | Any | Any | UrlTestMode Wildcard, CloudType Government |
| Private Link | Any | Any | EndpointType Private |
| Service Principal | Any | Any | AuthMethod EntraIDApp |

> **Note:** Software Inventory, SQL Discovery, Web App Discovery, and Dependency Analysis
> are post-discovery features configured in the appliance configuration manager after setup.
> They are validated by the appliance itself and are not part of this pre-setup script.

---

**Copy and paste any example above to get started quickly!** 🚀

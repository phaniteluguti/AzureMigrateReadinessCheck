# Azure Migrate Appliance Readiness Check

Comprehensive PowerShell script to validate prerequisites, network connectivity, authentication, and Azure RBAC permissions required for Azure Migrate appliance deployment.

## 📋 Overview

This script performs a complete readiness assessment for Azure Migrate appliance deployment, covering:

- ✅ **Prerequisites**: PowerShell version, execution policy, OS version, hardware requirements
- ✅ **Network Connectivity**: Azure public/private endpoints, SQL ports, Web App ports
- ✅ **Azure Authentication**: Device Code Flow and Entra ID App Registration methods
- ✅ **RBAC Validation**: Subscription and resource group permissions
- ✅ **Migration Configuration**: Agentless (VMware, Hyper-V) and Agent-based (Physical servers)
- ✅ **Physical Servers**: CSV-based connectivity validation
- ✅ **Comprehensive Reporting**: HTML report with detailed findings and recommendations

---

## 🚀 Quick Start

### Interactive Mode (Recommended for first-time use)

```powershell
.\AzureMigrateApplianceReadinessCheck.ps1
```

The script will guide you through all options with prompts.

### Parameter-Based Mode (For automation)

```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -EndpointType Public `
    -AuthMethod DeviceCodeFlow `
    -IncludeSQLDiscovery $true `
    -SQLPort 1433 `
    -InteractiveMode $false
```

---

## 📚 Prerequisites

### System Requirements

- **Operating System**: Windows Server 2019, 2022, or 2025
- **PowerShell**: Version 5.1 or later
- **Modules**: Az.Accounts, Az.Resources (will warn if missing)
- **Permissions**: Administrator privileges for registry access and system checks

### Azure Requirements

- Active Azure subscription
- **Contributor** role on subscription or resource group where Azure Migrate project will be deployed
- One of the following authentication methods:
  - Device Code Flow enabled in Azure AD (or exemption granted)
  - OR Entra ID App Registration with certificate-based authentication

---

## 📖 Usage

### Parameters

| Parameter | Type | Required | Description | Default |
|-----------|------|----------|-------------|---------|
| `InteractiveMode` | Boolean | No | Run with interactive prompts | `$true` |
| `MigrationApproach` | String | No* | 'Agentless' or 'AgentBased' | Prompted |
| `DiscoveryType` | String | No* | 'VMware', 'HyperV', or 'Physical' | Prompted |
| `EndpointType` | String | No | 'Public' or 'Private' | `Public` |
| `AuthMethod` | String | No | 'DeviceCodeFlow' or 'EntraIDApp' | Prompted |
| `SubscriptionId` | String | No | Azure Subscription ID | Prompted |
| `ResourceGroupName` | String | No | Azure Resource Group name | Prompted |
| `PhysicalServersCSV` | String | No | Path to CSV file (hostname,ip) | Prompted |
| `IncludeSQLDiscovery` | Boolean | No | Enable SQL Server discovery checks | `$false` |
| `SQLPort` | Integer | No | SQL Server port | `1433` |
| `IncludeWebAppDiscovery` | Boolean | No | Enable Web App discovery checks | `$false` |
| `LogPath` | String | No | Path for log file | Script directory |
| `ReportPath` | String | No | Path for HTML report | Script directory |

*Required in non-interactive mode

---

## 🎯 Migration Approaches

### 1. Agentless Migration (VMware & Hyper-V)

**Use Case**: Organizations with VMware vCenter or Hyper-V environments

**Checks Performed**:
- Discovery: Server metadata, performance data, dependencies
- Replication: Agentless replication capabilities
- Network connectivity to Azure Migrate services
- vCenter/Hyper-V host connectivity requirements

**Example**:
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -IncludeSQLDiscovery $true
```

**Reference**: [VMware Support Matrix](https://learn.microsoft.com/azure/migrate/migrate-support-matrix-vmware)

### 2. Agent-Based Migration (Physical Servers)

**Use Case**: Physical servers, unsupported virtualization platforms, AWS/GCP VMs

**Checks Performed**:
- Discovery: Server metadata and performance data
- Network connectivity to discovery endpoints
- Physical server connectivity validation (via CSV)

**CSV Format** (PhysicalServers.csv):
```csv
hostname,ip
server01,192.168.1.10
server02,192.168.1.11
webserver,10.20.30.40
```

**Example**:
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach AgentBased `
    -DiscoveryType Physical `
    -PhysicalServersCSV "C:\Servers.csv"
```

**Reference**: [Physical Server Support Matrix](https://learn.microsoft.com/azure/migrate/migrate-support-matrix-physical)

---

## 🔐 Authentication Methods

### Device Code Flow (Recommended for Manual Setup)

User-friendly browser-based authentication. The script opens Edge browser for sign-in.

**When to Use**:
- Manual appliance configuration
- Interactive deployment scenarios
- Testing and validation

**Troubleshooting**: If Device Code Flow is blocked:
1. Request exemption from Azure AD administrator
2. Use Entra ID App Registration method instead

**Error Reference**: [Troubleshoot Device Code Flow](https://learn.microsoft.com/azure/migrate/troubleshoot-appliance-discovery#error-50072)

### Entra ID App Registration (For Automated/Restricted Environments)

Certificate-based service principal authentication.

**When to Use**:
- Device Code Flow is blocked by policy
- Automated deployments
- Compliance requirements for service principals

**Setup Steps**:
1. Create Entra ID application: [App Registration Guide](https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app#1register-a-microsoft-entra-id-application-and-assign-permissions)
2. Generate certificate (provided in guide)
3. Upload public certificate to Entra ID app
4. Install private certificate on appliance
5. Update registry values (script in guide)

**Script Validation**: The script validates:
- Registry configuration exists
- Certificate is installed and valid
- Certificate has not expired
- Service principal configuration is correct

---

## 🌐 Network Connectivity

### Public Endpoints

The script tests connectivity to essential Azure services:

- **Authentication**: login.microsoftonline.com, *.msftauth.net
- **Azure Portal**: portal.azure.com
- **Management**: management.azure.com
- **Storage**: *.blob.core.windows.net
- **Service Bus**: *.servicebus.windows.net
- **Key Vault**: vault.azure.net
- **Updates**: aka.ms/*, download.microsoft.com

### Private Endpoints

For organizations using Azure Private Link:

**Still Required (Public)**:
- portal.azure.com
- login.microsoftonline.com
- Authentication endpoints

**Via Private Link**:
- management.azure.com
- *.blob.core.windows.net
- Azure Migrate service endpoints

**Reference**: [Private Link Setup](https://learn.microsoft.com/azure/migrate/how-to-use-azure-migrate-with-private-endpoints)

---

## 📊 Report Output

### HTML Report

The script generates a comprehensive HTML report with:

- **Executive Summary**: Pass/Fail/Warning counts
- **Category Sections**: Prerequisites, Network, Authentication, RBAC
- **Detailed Results**: Status, details, and recommendations for each check
- **Critical Issues**: Highlighted failures requiring immediate attention

**Report Features**:
- Color-coded status indicators
- Expandable details
- Actionable recommendations with links
- Professional Microsoft-compatible styling

### Log File

Timestamped log file capturing all script actions, including:
- Verbose execution details
- Error messages and stack traces
- Decision points and user inputs
- Network test results

---

## 📋 Example Scenarios

### Scenario 1: VMware Agentless Migration with SQL Discovery

```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType VMware `
    -EndpointType Public `
    -AuthMethod DeviceCodeFlow `
    -IncludeSQLDiscovery $true `
    -SQLPort 1433 `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -ResourceGroupName "AzureMigrateRG"
```

### Scenario 2: Physical Servers with Agent-Based Discovery

```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach AgentBased `
    -DiscoveryType Physical `
    -PhysicalServersCSV "C:\PhysicalServers.csv" `
    -AuthMethod EntraIDApp `
    -InteractiveMode $false
```

### Scenario 3: Hyper-V with Private Endpoints

```powershell
.\AzureMigrateApplianceReadinessCheck.ps1 `
    -MigrationApproach Agentless `
    -DiscoveryType HyperV `
    -EndpointType Private `
    -IncludeWebAppDiscovery $true
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Execution policy restricts script execution"

**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. "Az.Accounts module not found"

**Solution**:
```powershell
Install-Module -Name Az.Accounts -Repository PSGallery -Force
Install-Module -Name Az.Resources -Repository PSGallery -Force
```

#### 3. "Device Code Flow is blocked"

**Error**: `AADSTS50072: User account is disabled`

**Solutions**:
- Request Device Code Flow exemption from Azure AD admin
- Use Entra ID App Registration method
- Reference: [DCF Error 50072](https://learn.microsoft.com/azure/migrate/troubleshoot-appliance-discovery#error-50072)

#### 4. "Cannot validate RBAC permissions"

**Solution**: Ensure you have one of:
- **Owner** or **Contributor** role at subscription level
- **Contributor** role at resource group level

**Grant Role**:
```powershell
New-AzRoleAssignment `
    -SignInName "user@domain.com" `
    -RoleDefinitionName "Contributor" `
    -Scope "/subscriptions/{subscription-id}"
```

#### 5. "Physical servers not reachable"

**Checklist**:
- ✅ CSV format is correct (hostname,ip)
- ✅ Network connectivity from appliance to servers
- ✅ Firewall allows ICMP (ping)
- ✅ DNS resolution works
- ✅ IP addresses are correct

---

## 📚 Additional Resources

### Microsoft Learn Documentation

- [Azure Migrate Overview](https://learn.microsoft.com/azure/migrate/migrate-services-overview)
- [Appliance Architecture](https://learn.microsoft.com/azure/migrate/migrate-appliance)
- [VMware Support Matrix](https://learn.microsoft.com/azure/migrate/migrate-support-matrix-vmware)
- [Hyper-V Support Matrix](https://learn.microsoft.com/azure/migrate/migrate-support-matrix-hyper-v)
- [Physical Server Support](https://learn.microsoft.com/azure/migrate/migrate-support-matrix-physical)
- [Prepare Azure Accounts](https://learn.microsoft.com/azure/migrate/prepare-azure-accounts)
- [Network Requirements](https://learn.microsoft.com/azure/migrate/migrate-appliance#url-access)
- [Private Link Setup](https://learn.microsoft.com/azure/migrate/how-to-use-azure-migrate-with-private-endpoints)
- [Entra ID App Registration](https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app)

### Support

For issues with:
- **This Script**: Review logs and HTML report for detailed error messages
- **Azure Migrate Service**: [Troubleshooting Guide](https://learn.microsoft.com/azure/migrate/troubleshoot-general)
- **Azure Support**: Create support ticket in Azure Portal

---

## 🎯 Best Practices

1. **Run Before Appliance Deployment**: Identify and resolve issues before starting appliance setup
2. **Use Interactive Mode First**: Understand all options before scripting
3. **Review HTML Report**: Share with team for validation
4. **Keep Logs**: Retain for troubleshooting and audit purposes
5. **Regular Re-validation**: Run periodically to ensure continued compliance
6. **Test Connectivity**: Validate network paths before production migration
7. **Document Decisions**: Keep records of authentication method and configuration choices

---

## 📝 Version History

### Version 1.0 (April 2, 2026)
- Initial release
- Support for Agentless (VMware, Hyper-V) and Agent-based (Physical) migrations
- Device Code Flow and Entra ID App Registration authentication
- Public and Private endpoint validation
- Physical server CSV connectivity testing
- SQL Server and Web App discovery port checks
- Comprehensive HTML reporting
- Color-coded console output
- Detailed logging

---

## 📄 License

This script is provided as-is for Azure Migrate appliance readiness validation.

---

## 👥 Contributing

Suggestions and improvements are welcome. Please ensure any modifications maintain:
- Comprehensive error handling
- Detailed logging
- Clear user guidance
- Microsoft Learn documentation references

---

## ⚠️ Disclaimer

This script performs validation checks only. It does not:
- Install Azure Migrate appliance
- Modify Azure resources
- Deploy infrastructure
- Perform actual migration

Always review the generated report and recommendations before proceeding with appliance deployment.

---

**Happy Migrating! 🚀**

For questions or issues, refer to [Azure Migrate Documentation](https://learn.microsoft.com/azure/migrate/) or contact Azure Support.

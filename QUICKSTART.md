# Azure Migrate Appliance Readiness Check - Quick Start Guide

## 🚀 Getting Started in 3 Steps

### Step 1: Open PowerShell as Administrator
Right-click PowerShell and select "Run as Administrator"

### Step 2: Navigate to Script Directory
```powershell
cd C:\Users\pteluguti
```

### Step 3: Run the Script
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1
```

---

## 📝 What the Script Will Do

The script will guide you through:

1. **Accept Information Popup** - Read about Azure Migrate and click "Accept & Close"
2. **Select Migration Approach** - Choose Agentless or Agent-Based
3. **Select Discovery Type** - Choose VMware, Hyper-V, or Physical
4. **Select Cloud Type** - Choose Public or Government
5. **Network Testing** - Test connectivity to Azure endpoints
6. **Authentication** - Sign in to Azure via browser (Device Code Flow)
7. **Permissions Check** - Validate Contributor role and resource providers
8. **Report Generation** - Create HTML report with all findings

> **Note:** Post-discovery features (Software Inventory, SQL/Web App Discovery, Dependency Analysis)
> are configured in the appliance configuration manager after setup.

---

## ⏱️ Estimated Time

**Total Duration**: 5-10 minutes
- Prerequisites: 1 minute
- Configuration: 2 minutes
- Network tests: 2-3 minutes
- Authentication: 1-2 minutes
- RBAC validation: 1 minute
- Report generation: 30 seconds

---

## 📊 What You'll Get

### 1. Console Output
Real-time color-coded progress:
- 🟢 Green = Success
- 🔴 Red = Failed
- 🟡 Yellow = Warning
- 🔵 Blue = Information

### 2. Log File
`AzureMigrateReadiness_YYYYMMDD_HHMMSS.log`
- Detailed execution log
- All checks and results
- Error messages and troubleshooting info

### 3. HTML Report
`AzureMigrateReadiness_YYYYMMDD_HHMMSS.html`
- Professional formatted report
- Executive summary with counts
- Detailed findings by category
- Recommendations for failures
- Opens automatically in browser

---

## 🎯 Common Scenarios

### Scenario 1: VMware Environment
```powershell
# Interactive mode - just press Enter for defaults
.\AzureMigrateApplianceReadinessCheck.ps1
# When prompted:
# - Migration Approach: 1 (Agentless)
# - Discovery Type: 1 (VMware)
# - Cloud Type: 1 (Public)
```

### Scenario 2: Physical Servers
```powershell
# First, create CSV file with your servers
# PhysicalServers.csv:
# hostname,ip
# server01,192.168.1.10
# server02,192.168.1.11

# Run script
.\AzureMigrateApplianceReadinessCheck.ps1
# When prompted:
# - Migration Approach: 2 (AgentBased)
# - Discovery Type: 3 (Physical)
# - CSV Path: C:\PhysicalServers.csv
```

### Scenario 3: Hyper-V Environment
```powershell
.\AzureMigrateApplianceReadinessCheck.ps1
# When prompted:
# - Migration Approach: 1 (Agentless)
# - Discovery Type: 2 (HyperV)
# - Cloud Type: 1 (Public)
```

---

## ⚠️ Troubleshooting

### "Script cannot be loaded" or "Execution policy" error

**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Module Az.Accounts not found"

**Solution**:
```powershell
Install-Module -Name Az.Accounts -Repository PSGallery -Force
Install-Module -Name Az.Resources -Repository PSGallery -Force
```

### Authentication Window Doesn't Open

**Solution**:
- Check if Edge browser is installed
- Manually browse to the device code URL shown in console
- Try using Entra ID App Registration method instead

### No Permissions to Create Resource Group

**Solution**: Contact your Azure administrator to grant Contributor role:
- At subscription level (recommended), OR
- At resource group level where Azure Migrate will be deployed

---

## 📋 Before You Run

### Checklist

✅ Windows Server 2019, 2022, or 2025  
✅ PowerShell 5.1 or later  
✅ Administrator privileges  
✅ Internet connectivity (or Private Link configured)  
✅ Azure subscription access  
✅ Contributor permissions (or prepared to request)  
✅ For Physical: CSV file with server list  

---

## 🔍 Understanding Results

### ✅ All Checks Passed
Your environment is ready for Azure Migrate appliance deployment!
**Next Step**: Deploy the appliance using Azure Portal or PowerShell installer

### ⚠️ Warnings Found
Most checks passed but some items need attention.
**Review**: Check HTML report for recommendations
**Action**: Address warnings before production migration

### ❌ Failures Found
Critical issues prevent appliance deployment.
**Review**: Check HTML report for failed items
**Action**: Fix all failed checks before proceeding

---

## 📞 Need Help?

1. **Review the HTML Report** - Detailed recommendations for each issue
2. **Check the Log File** - Technical details and error messages
3. **Read README.md** - Comprehensive documentation
4. **Azure Migrate Docs** - https://learn.microsoft.com/azure/migrate/
5. **Azure Support** - Create ticket in Azure Portal

---

## 💡 Pro Tips

1. **Save the Report** - Share with your team for review
2. **Re-run After Fixes** - Validate that issues are resolved
3. **Use Parameters** - Speed up re-runs with parameter mode
4. **Test Connectivity** - Run before actual appliance deployment
5. **Keep Logs** - Useful for troubleshooting later

---

## 📚 Next Steps After Successful Validation

1. **Deploy Appliance**:
   - VMware: Download OVA template or use PowerShell installer
   - Hyper-V: Download VHD or use PowerShell installer
   - Physical: Download PowerShell installer

2. **Configure Appliance**:
   - Open appliance configuration manager (https://appliance-name:44368)
   - Register with Azure Migrate project
   - Add credentials for discovery

3. **Start Discovery**:
   - VMware: Connect to vCenter Server
   - Hyper-V: Add Hyper-V hosts
   - Physical: Add server list

4. **Review Discovered Inventory**:
   - View in Azure Portal
   - Create assessments
   - Plan migration waves

---

**Ready? Let's validate your environment!** 🚀

```powershell
.\AzureMigrateApplianceReadinessCheck.ps1
```

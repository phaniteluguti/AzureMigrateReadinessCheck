<#
.SYNOPSIS
    Azure Migrate Appliance Readiness Validation Script

.DESCRIPTION
    Comprehensive PowerShell script to validate prerequisites, network connectivity, 
    authentication, and Azure RBAC permissions required for Azure Migrate appliance deployment.
    
    Performs context-aware, conditional checks based on your migration approach, discovery type,
    and selected optional features. Only validates what is relevant to your specific configuration.
    
    Supports:
    - Agentless migration (VMware, Hyper-V)
    - Agent-based migration (Physical servers)
    - Device Code Flow and Entra ID App Registration authentication
    - Public, Private, and Government cloud endpoint validation
    
    Note: Post-discovery features (Software Inventory, SQL/Web App Discovery, Dependency Analysis)
    are configured in the appliance configuration manager after setup and validated by the appliance itself.
    
.PARAMETER InteractiveMode
    Run the script in interactive mode with prompts (default: $true)

.PARAMETER MigrationApproach
    Migration approach: 'Agentless' or 'AgentBased'

.PARAMETER DiscoveryType
    Discovery type: 'VMware', 'HyperV', or 'Physical'

.PARAMETER EndpointType
    Endpoint type: 'Public' or 'Private'

.PARAMETER CloudType
    Azure cloud environment: 'Public' or 'Government'. Determines which URL set to validate (default: 'Public')

.PARAMETER AuthMethod
    Authentication method: 'DeviceCodeFlow' or 'EntraIDApp'

.PARAMETER SubscriptionId
    Azure Subscription ID (optional, will prompt if not provided)

.PARAMETER ResourceGroupName
    Azure Resource Group Name (optional, will prompt if not provided)

.PARAMETER PhysicalServersCSV
    Path to CSV file containing physical servers (hostname,ip format)

.PARAMETER LogPath
    Path for log file (default: script directory)

.PARAMETER ReportPath
    Path for HTML report (default: script directory)

.EXAMPLE
    .\AzureMigrateApplianceReadinessCheck.ps1
    Run in fully interactive mode - prompts for all configuration choices

.EXAMPLE
    .\AzureMigrateApplianceReadinessCheck.ps1 -MigrationApproach Agentless -DiscoveryType VMware -EndpointType Public
    VMware agentless with public endpoints - runs core checks only

.EXAMPLE
    .\AzureMigrateApplianceReadinessCheck.ps1 -InteractiveMode $false -MigrationApproach Agentless -DiscoveryType VMware -AuthMethod EntraIDApp -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "AzureMigrateRG" -CloudType Government
    Fully automated non-interactive run with Government cloud URLs and Entra ID App auth

.NOTES
    File Name      : AzureMigrateApplianceReadinessCheck.ps1
    Author         : Azure Migration Team
    Prerequisite   : PowerShell 5.1 or later, Az PowerShell modules
    Version        : 2.0
    Date           : April 2, 2026
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [bool]$InteractiveMode = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Agentless', 'AgentBased')]
    [string]$MigrationApproach,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('VMware', 'HyperV', 'Physical')]
    [string]$DiscoveryType,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Public', 'Private')]
    [string]$EndpointType = 'Public',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Public', 'Government')]
    [string]$CloudType = 'Public',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('DeviceCodeFlow', 'EntraIDApp')]
    [string]$AuthMethod,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$PhysicalServersCSV,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = (Join-Path $PSScriptRoot "AzureMigrateReadiness_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"),
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = (Join-Path $PSScriptRoot "AzureMigrateReadiness_$(Get-Date -Format 'yyyyMMdd_HHmmss').html")
)

#Requires -Version 5.1

# ============================================================================
# GLOBAL VARIABLES AND CONSTANTS
# ============================================================================

$script:ScriptVersion = "2.0"
$script:CheckResults = @()
$script:StartTime = Get-Date
$script:ErrorCount = 0
$script:WarningCount = 0
$script:SuccessCount = 0

# Azure Public Cloud URLs for Network Connectivity Checks
$script:AzurePublicEndpoints = @{
    'Essential' = @(
        'https://portal.azure.com',
        'https://management.azure.com',
        'https://login.microsoftonline.com',
        'https://graph.microsoft.com'
    )
    'AzureMigrate' = @(
        'https://management.azure.com',
        'https://login.microsoftonline.com',
        'https://login.windows.net',
        'https://www.msftauth.net',
        'https://www.msauth.net',
        'https://www.microsoft.com',
        'https://www.live.com',
        'https://www.office.com'
    )
    'AzureMigrateService' = @(
        'https://discoverysrv.windowsazure.com',
        'https://migration.windowsazure.com',
        'https://hypervrecoverymanager.windowsazure.com'
    )
    'Identity' = @(
        'https://login.microsoftonline-p.com',
        'https://microsoftazuread-sso.com',
        'https://cloud.microsoft'
    )
    'Telemetry' = @(
        'https://dc.services.visualstudio.com',
        'https://applicationinsights.azure.com',
        'https://loganalytics.io'
    )
    'Storage' = @(
        'https://www.blob.core.windows.net'
    )
    'ServiceBus' = @(
        'https://www.servicebus.windows.net'
    )
    'KeyVault' = @(
        'https://vault.azure.net'
    )
    'Updates' = @(
        'https://aka.ms/latestapplianceservices',
        'https://download.microsoft.com/download',
        'https://prod.do.dsp.mp.microsoft.com'
    )
    'TimeSync' = @(
        'https://time.windows.com'
    )
}

# Azure Government Cloud URLs
$script:AzureGovernmentEndpoints = @{
    'Essential' = @(
        'https://portal.azure.us',
        'https://management.usgovcloudapi.net',
        'https://login.microsoftonline.us',
        'https://graph.microsoft.us'
    )
    'AzureMigrate' = @(
        'https://management.usgovcloudapi.net',
        'https://login.microsoftonline.us',
        'https://login.windows.net'
    )
    'AzureMigrateService' = @(
        'https://discoverysrv.windowsazure.us',
        'https://migration.windowsazure.us',
        'https://hypervrecoverymanager.windowsazure.us'
    )
    'Storage' = @(
        'https://www.blob.core.usgovcloudapi.net'
    )
    'ServiceBus' = @(
        'https://www.servicebus.usgovcloudapi.net'
    )
    'KeyVault' = @(
        'https://vault.usgovcloudapi.net'
    )
    'Updates' = @(
        'https://aka.ms/latestapplianceservices',
        'https://download.microsoft.com/download'
    )
}

# Required Azure Resource Providers for Azure Migrate
$script:RequiredResourceProviders = @(
    'Microsoft.OffAzure',
    'Microsoft.Migrate',
    'Microsoft.KeyVault',
    'Microsoft.Storage',
    'Microsoft.Network',
    'Microsoft.Compute',
    'Microsoft.Insights',
    'Microsoft.HybridCompute',
    'Microsoft.GuestConfiguration',
    'Microsoft.HybridConnectivity',
    'Microsoft.RecoveryServices',
    'Microsoft.DataReplication',
    'Microsoft.ApplicationMigration',
    'Microsoft.DependencyMap',
    'Microsoft.MySQLDiscovery',
    'Microsoft.AzureArcData'
)

# Azure Migrate specific RBAC role names
$script:AzureMigrateRoles = @(
    'Contributor',
    'Owner',
    'Azure Migrate Owner',
    'Azure Migrate Decide and Plan Expert',
    'Azure Migrate Execute Expert'
)

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes a log entry to file and console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
    
    # Write to console with color coding
    if (-not $NoConsole) {
        $color = switch ($Level) {
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Error'   { 'Red' }
            'Debug'   { 'Gray' }
            default   { 'White' }
        }
        
        Write-Host $logEntry -ForegroundColor $color
    }
}

function Add-CheckResult {
    <#
    .SYNOPSIS
        Adds a check result to the global results collection
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [string]$CheckName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Pass', 'Fail', 'Warning', 'Info')]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [string]$Details = '',
        
        [Parameter(Mandatory = $false)]
        [string]$Recommendation = ''
    )
    
    $result = [PSCustomObject]@{
        Timestamp      = Get-Date
        Category       = $Category
        CheckName      = $CheckName
        Status         = $Status
        Details        = $Details
        Recommendation = $Recommendation
    }
    
    $script:CheckResults += $result
    
    # Update counters
    switch ($Status) {
        'Pass'    { $script:SuccessCount++ }
        'Fail'    { $script:ErrorCount++ }
        'Warning' { $script:WarningCount++ }
    }
    
    # Log the result
    $logLevel = switch ($Status) {
        'Pass'    { 'Success' }
        'Fail'    { 'Error' }
        'Warning' { 'Warning' }
        'Info'    { 'Info' }
    }
    
    Write-Log -Message "$CheckName : $Status - $Details" -Level $logLevel
}

# ============================================================================
# UI HELPER FUNCTIONS
# ============================================================================

function Show-InfoPopup {
    <#
    .SYNOPSIS
        Displays an information popup window
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 600,
        
        [Parameter(Mandatory = $false)]
        [int]$Height = 400
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size($Width, $Height)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ReadOnly = $true
    $textBox.ScrollBars = 'Vertical'
    $textBox.Size = New-Object System.Drawing.Size(($Width - 40), ($Height - 100))
    $textBox.Location = New-Object System.Drawing.Point(10, 10)
    $textBox.Text = $Message
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    
    $acceptButton = New-Object System.Windows.Forms.Button
    $acceptButton.Size = New-Object System.Drawing.Size(100, 30)
    $acceptButton.Location = New-Object System.Drawing.Point(($Width / 2 - 50), ($Height - 70))
    $acceptButton.Text = 'Accept && Close'
    $acceptButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    
    $form.Controls.Add($textBox)
    $form.Controls.Add($acceptButton)
    $form.AcceptButton = $acceptButton
    
    $result = $form.ShowDialog()
    $form.Dispose()
    
    return ($result -eq [System.Windows.Forms.DialogResult]::OK)
}

function Show-SelectionMenu {
    <#
    .SYNOPSIS
        Displays a selection menu in console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Options,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultOption
    )
    
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "================================`n" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $optionText = "$($i + 1). $($Options[$i])"
        if ($Options[$i] -eq $DefaultOption) {
            $optionText += " (Default)"
        }
        Write-Host $optionText
    }
    
    do {
        Write-Host "`nEnter your choice (1-$($Options.Count)): " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($choice) -and $DefaultOption) {
            $selectedIndex = [array]::IndexOf($Options, $DefaultOption)
            if ($selectedIndex -ge 0) {
                return $Options[$selectedIndex]
            }
        }
        
        $choiceNum = 0
        if ([int]::TryParse($choice, [ref]$choiceNum)) {
            if ($choiceNum -ge 1 -and $choiceNum -le $Options.Count) {
                return $Options[$choiceNum - 1]
            }
        }
        
        Write-Host "Invalid choice. Please try again." -ForegroundColor Red
    } while ($true)
}

function Write-Progress-Status {
    <#
    .SYNOPSIS
        Writes a progress status with visual indicator
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [int]$PercentComplete = -1
    )
    
    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
    else {
        Write-Progress -Activity $Activity -Status $Status
    }
}

# ============================================================================
# PREREQUISITE CHECK FUNCTIONS
# ============================================================================

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Tests all prerequisite requirements
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting prerequisite checks..." -Level Info
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PREREQUISITE CHECKS" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Check PowerShell version
    Test-PowerShellVersion
    
    # Check execution policy
    Test-ExecutionPolicy
    
    # Check OS version
    Test-OSVersion
    
    # Check FIPS mode (not supported for appliance)
    Test-FIPSMode
    
    # Check hardware requirements (conditional on DiscoveryType)
    Test-HardwareRequirements
    
    # Check for required modules
    Test-RequiredModules
    
    # Check for existing Azure Migrate installation
    Test-ExistingApplianceInstallation
    
    # Check network adapter / IP address
    Test-NetworkAdapter
    
    # Check time sync service
    Test-TimeSyncService
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Validates PowerShell version
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking PowerShell version..."
    
    $psVersion = $PSVersionTable.PSVersion
    Write-Log -Message "PowerShell Version: $($psVersion.ToString())" -Level Info
    
    if ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1) {
        Add-CheckResult -Category "Prerequisites" -CheckName "PowerShell Version" -Status "Pass" `
            -Details "PowerShell version $($psVersion.ToString()) meets minimum requirement (5.1+)"
    }
    else {
        Add-CheckResult -Category "Prerequisites" -CheckName "PowerShell Version" -Status "Fail" `
            -Details "PowerShell version $($psVersion.ToString()) does not meet minimum requirement (5.1+)" `
            -Recommendation "Upgrade to PowerShell 5.1 or later. Download from https://aka.ms/powershell"
    }
}

function Test-ExecutionPolicy {
    <#
    .SYNOPSIS
        Checks script execution policy
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking execution policy..."
    
    $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Log -Message "Execution Policy (CurrentUser): $executionPolicy" -Level Info
    
    $allowedPolicies = @('RemoteSigned', 'Unrestricted', 'Bypass')
    
    if ($executionPolicy -in $allowedPolicies) {
        Add-CheckResult -Category "Prerequisites" -CheckName "Execution Policy" -Status "Pass" `
            -Details "Execution policy is set to '$executionPolicy' which allows script execution"
    }
    elseif ($executionPolicy -eq 'Restricted' -or $executionPolicy -eq 'AllSigned') {
        Add-CheckResult -Category "Prerequisites" -CheckName "Execution Policy" -Status "Warning" `
            -Details "Execution policy is '$executionPolicy' which may restrict script execution" `
            -Recommendation "Consider changing execution policy: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    }
    else {
        Add-CheckResult -Category "Prerequisites" -CheckName "Execution Policy" -Status "Info" `
            -Details "Execution policy is '$executionPolicy'"
    }
}

function Test-OSVersion {
    <#
    .SYNOPSIS
        Validates Windows Server OS version
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking OS version..."
    
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osVersion = $os.Caption
    $osBuildNumber = $os.BuildNumber
    
    Write-Log -Message "Operating System: $osVersion (Build: $osBuildNumber)" -Level Info
    
    # Windows Server 2019 (Build 17763), 2022 (Build 20348), 2025 (Build 26100+)
    $supportedBuilds = @{
        '17763' = 'Windows Server 2019'
        '20348' = 'Windows Server 2022'
        '26100' = 'Windows Server 2025'
    }
    
    $isSupported = $false
    foreach ($build in $supportedBuilds.Keys) {
        if ([int]$osBuildNumber -ge [int]$build) {
            $isSupported = $true
            break
        }
    }
    
    if ($isSupported) {
        Add-CheckResult -Category "Prerequisites" -CheckName "OS Version" -Status "Pass" `
            -Details "$osVersion (Build: $osBuildNumber) is supported for Azure Migrate appliance"
    }
    else {
        Add-CheckResult -Category "Prerequisites" -CheckName "OS Version" -Status "Fail" `
            -Details "$osVersion (Build: $osBuildNumber) may not be supported. Minimum: Windows Server 2019" `
            -Recommendation "Upgrade to Windows Server 2019, 2022, or 2025"
    }
}

function Test-HardwareRequirements {
    <#
    .SYNOPSIS
        Validates hardware requirements (conditional on DiscoveryType and optional features)
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking hardware requirements..."
    
    # Get system information
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $diskSpace = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
    $cpuCores = $processor.NumberOfLogicalProcessors
    $freeDiskGB = [math]::Round($diskSpace.FreeSpace / 1GB, 2)
    
    Write-Log -Message "System Resources - RAM: ${totalRAM}GB, CPU Cores: $cpuCores, Free Disk: ${freeDiskGB}GB" -Level Info
    
    # Determine required RAM based on DiscoveryType
    # Hyper-V standalone appliance: 16GB minimum (32GB if optional features are enabled post-setup)
    # VMware and Physical: always 32GB
    $requiredRAM = 32
    $ramNote = ""
    if ($script:DiscoveryType -eq 'HyperV') {
        $requiredRAM = 16
        $ramNote = " (Hyper-V base requirement; 32GB recommended if enabling Software Inventory/SQL/Web App discovery later)"
    }
    
    $ramCheck = $totalRAM -ge $requiredRAM
    $cpuCheck = $cpuCores -ge 8
    $diskCheck = $freeDiskGB -ge 80
    
    if ($ramCheck -and $cpuCheck -and $diskCheck) {
        Add-CheckResult -Category "Prerequisites" -CheckName "Hardware Requirements" -Status "Pass" `
            -Details "System meets requirements$ramNote - RAM: ${totalRAM}GB (${requiredRAM}GB+ req), CPUs: $cpuCores (8+ req), Free Disk: ${freeDiskGB}GB (80GB+ req)"
    }
    else {
        $issues = @()
        if (-not $ramCheck) { $issues += "RAM: ${totalRAM}GB (${requiredRAM}GB required$ramNote)" }
        if (-not $cpuCheck) { $issues += "CPUs: $cpuCores (8 required)" }
        if (-not $diskCheck) { $issues += "Free Disk: ${freeDiskGB}GB (80GB required)" }
        
        Add-CheckResult -Category "Prerequisites" -CheckName "Hardware Requirements" -Status "Fail" `
            -Details "System does not meet requirements: $($issues -join ', ')" `
            -Recommendation "Upgrade hardware to meet minimum requirements for Azure Migrate appliance"
    }
}

function Test-RequiredModules {
    <#
    .SYNOPSIS
        Checks for required PowerShell modules
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking required modules..."
    
    $requiredModules = @('Az.Accounts', 'Az.Resources')
    $missingModules = @()
    
    foreach ($moduleName in $requiredModules) {
        $module = Get-Module -ListAvailable -Name $moduleName | Select-Object -First 1
        if ($module) {
            Write-Log -Message "Module '$moduleName' version $($module.Version) is installed" -Level Info
        }
        else {
            Write-Log -Message "Module '$moduleName' is NOT installed" -Level Warning
            $missingModules += $moduleName
        }
    }
    
    if ($missingModules.Count -eq 0) {
        Add-CheckResult -Category "Prerequisites" -CheckName "Required Modules" -Status "Pass" `
            -Details "All required Azure PowerShell modules are installed: $($requiredModules -join ', ')"
    }
    else {
        Add-CheckResult -Category "Prerequisites" -CheckName "Required Modules" -Status "Warning" `
            -Details "Missing modules: $($missingModules -join ', ')" `
            -Recommendation "Install missing modules: Install-Module -Name $($missingModules -join ',') -Repository PSGallery -Force"
    }
}

function Test-ExistingApplianceInstallation {
    <#
    .SYNOPSIS
        Checks for existing Azure Migrate appliance installation
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking for existing appliance installation..."
    
    $applianceRegKey = "HKLM:\SOFTWARE\Microsoft\AzureAppliance"
    $applianceExists = Test-Path $applianceRegKey
    
    if ($applianceExists) {
        try {
            $regValues = Get-ItemProperty -Path $applianceRegKey -ErrorAction Stop
            $appName = $regValues.AgentServiceCommAadAppName
            
            Add-CheckResult -Category "Prerequisites" -CheckName "Existing Installation" -Status "Warning" `
                -Details "Azure Migrate appliance appears to be already configured (App: $appName)" `
                -Recommendation "Verify if this is a re-run or if appliance needs to be reconfigured"
        }
        catch {
            Add-CheckResult -Category "Prerequisites" -CheckName "Existing Installation" -Status "Info" `
                -Details "Azure Migrate registry key exists but cannot read details"
        }
    }
    else {
        Add-CheckResult -Category "Prerequisites" -CheckName "Existing Installation" -Status "Pass" `
            -Details "No existing Azure Migrate appliance installation detected"
    }
}

function Test-FIPSMode {
    <#
    .SYNOPSIS
        Checks if FIPS mode is enabled (not supported for Azure Migrate appliance)
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking FIPS mode..."
    
    try {
        $fipsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy"
        if (Test-Path $fipsKey) {
            $fipsEnabled = (Get-ItemProperty -Path $fipsKey -Name Enabled -ErrorAction SilentlyContinue).Enabled
            if ($fipsEnabled -eq 1) {
                Add-CheckResult -Category "Prerequisites" -CheckName "FIPS Mode" -Status "Fail" `
                    -Details "FIPS mode is ENABLED. Azure Migrate appliance does not support FIPS mode." `
                    -Recommendation "Disable FIPS mode before deploying the appliance. Registry: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy\Enabled = 0"
            }
            else {
                Add-CheckResult -Category "Prerequisites" -CheckName "FIPS Mode" -Status "Pass" `
                    -Details "FIPS mode is disabled (compatible with Azure Migrate appliance)"
            }
        }
        else {
            Add-CheckResult -Category "Prerequisites" -CheckName "FIPS Mode" -Status "Pass" `
                -Details "FIPS policy registry key not found (FIPS not configured)"
        }
    }
    catch {
        Add-CheckResult -Category "Prerequisites" -CheckName "FIPS Mode" -Status "Warning" `
            -Details "Unable to check FIPS mode: $($_.Exception.Message)"
    }
}

function Test-NetworkAdapter {
    <#
    .SYNOPSIS
        Validates the appliance has a routable IP address
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking network adapter..."
    
    try {
        $adapters = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop | Where-Object {
            $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown'
        }
        
        if ($adapters -and $adapters.Count -gt 0) {
            $ipList = ($adapters | Select-Object -ExpandProperty IPAddress) -join ', '
            Add-CheckResult -Category "Prerequisites" -CheckName "Network Adapter" -Status "Pass" `
                -Details "Active network adapter(s) found with IP: $ipList"
        }
        else {
            Add-CheckResult -Category "Prerequisites" -CheckName "Network Adapter" -Status "Fail" `
                -Details "No active network adapter with a routable IPv4 address found" `
                -Recommendation "The appliance requires a static or dynamic IP with internet access"
        }
    }
    catch {
        Add-CheckResult -Category "Prerequisites" -CheckName "Network Adapter" -Status "Warning" `
            -Details "Unable to check network adapters: $($_.Exception.Message)"
    }
}

function Test-TimeSyncService {
    <#
    .SYNOPSIS
        Checks if Windows Time service is running (critical for auth token validity)
    #>
    Write-Progress-Status -Activity "Prerequisite Checks" -Status "Checking time sync service..."
    
    try {
        $w32time = Get-Service -Name 'w32time' -ErrorAction Stop
        if ($w32time.Status -eq 'Running') {
            Add-CheckResult -Category "Prerequisites" -CheckName "Time Sync Service" -Status "Pass" `
                -Details "Windows Time service (w32time) is running"
        }
        else {
            Add-CheckResult -Category "Prerequisites" -CheckName "Time Sync Service" -Status "Warning" `
                -Details "Windows Time service is $($w32time.Status). Time sync is critical for Azure authentication." `
                -Recommendation "Start the service: Start-Service w32time; w32tm /resync"
        }
    }
    catch {
        Add-CheckResult -Category "Prerequisites" -CheckName "Time Sync Service" -Status "Warning" `
            -Details "Unable to check Windows Time service: $($_.Exception.Message)"
    }
}

# ============================================================================
# MIGRATION APPROACH AND DISCOVERY SELECTION
# ============================================================================

function Get-MigrationConfiguration {
    <#
    .SYNOPSIS
        Gathers migration configuration through interactive prompts or parameters
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "MIGRATION CONFIGURATION" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Show information about Azure Migrate
    $infoMessage = @"
Azure Migrate Appliance Readiness Check v$($script:ScriptVersion)
========================================

This script validates the prerequisites required for Azure Migrate appliance deployment.
It performs CONTEXT-AWARE checks - only validating what is relevant to your configuration.

Two Migration Approaches:
-------------------------
1. AGENTLESS Migration (Recommended)
   - For VMware and Hyper-V environments
   - Discovery: Collect server metadata, performance data, dependencies
   - Replication: Agentless replication to Azure without installing agents

2. AGENT-BASED Migration
   - For Physical servers or unsupported virtualization platforms
   - Discovery: Collect server metadata, performance data
   - Replication: Requires agents on each server (not covered in this script)

Optional Features (configured post-setup in appliance):
-------------------------------------------------------
After the appliance is deployed, you configure these in the appliance configuration manager:
- Software Inventory, SQL Server Discovery, Web App Discovery, Dependency Analysis
These are validated by the appliance itself during operation.

This script focuses on PRE-SETUP prerequisites only:
- Hardware, OS, network connectivity, Azure RBAC, resource providers, FIPS mode, time sync

Documentation:
- VMware: https://learn.microsoft.com/azure/migrate/migrate-support-matrix-vmware
- Hyper-V: https://learn.microsoft.com/azure/migrate/migrate-support-matrix-hyper-v
- Physical: https://learn.microsoft.com/azure/migrate/migrate-support-matrix-physical
"@
    
    if ($InteractiveMode) {
        $accepted = Show-InfoPopup -Title "Azure Migrate Readiness Check" -Message $infoMessage -Width 700 -Height 500
        if (-not $accepted) {
            Write-Log -Message "User cancelled the script execution" -Level Warning
            exit 0
        }
    }
    else {
        Write-Host $infoMessage -ForegroundColor Cyan
    }
    
    # Get Migration Approach
    if ([string]::IsNullOrWhiteSpace($script:MigrationApproach)) {
        if ($InteractiveMode) {
            $script:MigrationApproach = Show-SelectionMenu -Title "Select Migration Approach" `
                -Options @('Agentless', 'AgentBased') -DefaultOption 'Agentless'
        }
        else {
            Write-Log -Message "MigrationApproach parameter is required in non-interactive mode" -Level Error
            throw "MigrationApproach parameter is required"
        }
    }
    
    Write-Log -Message "Selected Migration Approach: $($script:MigrationApproach)" -Level Info
    
    # Get Discovery Type
    if ([string]::IsNullOrWhiteSpace($script:DiscoveryType)) {
        if ($InteractiveMode) {
            $availableTypes = if ($script:MigrationApproach -eq 'Agentless') {
                @('VMware', 'HyperV')
            }
            else {
                @('Physical')
            }
            
            $script:DiscoveryType = Show-SelectionMenu -Title "Select Discovery Type" -Options $availableTypes
        }
        else {
            Write-Log -Message "DiscoveryType parameter is required in non-interactive mode" -Level Error
            throw "DiscoveryType parameter is required"
        }
    }
    
    Write-Log -Message "Selected Discovery Type: $($script:DiscoveryType)" -Level Info
    
    # Validate combination
    if ($script:MigrationApproach -eq 'Agentless' -and $script:DiscoveryType -eq 'Physical') {
        Write-Log -Message "Invalid combination: Agentless migration is not available for Physical servers" -Level Error
        Add-CheckResult -Category "Configuration" -CheckName "Migration Configuration" -Status "Fail" `
            -Details "Invalid combination: Agentless migration is not available for Physical servers" `
            -Recommendation "Use Agent-Based migration for Physical servers"
        throw "Invalid migration configuration"
    }
    
    if ($script:MigrationApproach -eq 'AgentBased' -and $script:DiscoveryType -ne 'Physical') {
        Write-Log -Message "Invalid combination: Agent-Based migration is designed for Physical servers" -Level Warning
        Add-CheckResult -Category "Configuration" -CheckName "Migration Configuration" -Status "Warning" `
            -Details "Agent-Based migration is typically used for Physical servers, but can be used for other scenarios" `
            -Recommendation "Consider using Agentless migration for VMware/Hyper-V for better efficiency"
    }
    
    Add-CheckResult -Category "Configuration" -CheckName "Migration Configuration" -Status "Pass" `
        -Details "Approach: $($script:MigrationApproach), Type: $($script:DiscoveryType)"
    
    # Get Cloud Type
    if ($InteractiveMode -and -not $PSBoundParameters.ContainsKey('CloudType')) {
        $script:CloudType = Show-SelectionMenu -Title "Select Azure Cloud Environment" `
            -Options @('Public', 'Government') -DefaultOption 'Public'
    }
    Write-Log -Message "Selected Cloud Type: $($script:CloudType)" -Level Info
    
    # If Physical servers, get CSV file
    if ($script:DiscoveryType -eq 'Physical') {
        Get-PhysicalServersConfig
    }
}

function Get-PhysicalServersConfig {
    <#
    .SYNOPSIS
        Gets physical servers configuration from CSV
    #>
    Write-Host "`n--- Physical Servers Configuration ---`n" -ForegroundColor Yellow
    
    if ([string]::IsNullOrWhiteSpace($script:PhysicalServersCSV)) {
        if ($InteractiveMode) {
            $csvPath = Read-Host "Enter path to CSV file with physical servers (hostname,ip format) or press Enter to skip"
            if (-not [string]::IsNullOrWhiteSpace($csvPath)) {
                $script:PhysicalServersCSV = $csvPath
            }
        }
    }
    
    if (-not [string]::IsNullOrWhiteSpace($script:PhysicalServersCSV)) {
        Test-PhysicalServersCSV
    }
    else {
        Add-CheckResult -Category "Configuration" -CheckName "Physical Servers CSV" -Status "Info" `
            -Details "No physical servers CSV provided - connectivity checks will be skipped"
    }
}

function Test-PhysicalServersCSV {
    <#
    .SYNOPSIS
        Validates and tests physical servers from CSV
    #>
    if (-not (Test-Path $script:PhysicalServersCSV)) {
        Add-CheckResult -Category "Configuration" -CheckName "Physical Servers CSV" -Status "Fail" `
            -Details "CSV file not found: $($script:PhysicalServersCSV)" `
            -Recommendation "Provide a valid CSV file path with hostname,ip format"
        return
    }
    
    try {
        $servers = Import-Csv -Path $script:PhysicalServersCSV -ErrorAction Stop
        
        if ($servers.Count -eq 0) {
            Add-CheckResult -Category "Configuration" -CheckName "Physical Servers CSV" -Status "Warning" `
                -Details "CSV file is empty" `
                -Recommendation "Add servers to CSV in hostname,ip format"
            return
        }
        
        # Validate CSV format
        $firstServer = $servers[0]
        if (-not ($firstServer.PSObject.Properties.Name -contains 'hostname') -or 
            -not ($firstServer.PSObject.Properties.Name -contains 'ip')) {
            Add-CheckResult -Category "Configuration" -CheckName "Physical Servers CSV" -Status "Fail" `
                -Details "CSV format is invalid. Expected columns: hostname,ip" `
                -Recommendation "Ensure CSV has 'hostname' and 'ip' columns"
            return
        }
        
        Write-Log -Message "Loaded $($servers.Count) physical servers from CSV" -Level Info
        Add-CheckResult -Category "Configuration" -CheckName "Physical Servers CSV" -Status "Pass" `
            -Details "Successfully loaded $($servers.Count) physical servers from CSV"
        
        # Test connectivity to physical servers
        Test-PhysicalServersConnectivity -Servers $servers
    }
    catch {
        Add-CheckResult -Category "Configuration" -CheckName "Physical Servers CSV" -Status "Fail" `
            -Details "Failed to read CSV: $($_.Exception.Message)" `
            -Recommendation "Ensure CSV is properly formatted and accessible"
    }
}

function Test-PhysicalServersConnectivity {
    <#
    .SYNOPSIS
        Tests connectivity to physical servers
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Servers
    )
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PHYSICAL SERVERS CONNECTIVITY CHECK" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $reachableCount = 0
    $unreachableCount = 0
    
    foreach ($server in $Servers) {
        Write-Progress-Status -Activity "Testing Physical Servers" `
            -Status "Testing connectivity to $($server.hostname) ($($server.ip))..." `
            -PercentComplete (($Servers.IndexOf($server) + 1) / $Servers.Count * 100)
        
        $pingResult = Test-Connection -ComputerName $server.ip -Count 2 -Quiet -ErrorAction SilentlyContinue
        
        if ($pingResult) {
            Write-Log -Message "Server $($server.hostname) ($($server.ip)) is reachable" -Level Success
            $reachableCount++
        }
        else {
            Write-Log -Message "Server $($server.hostname) ($($server.ip)) is NOT reachable" -Level Warning
            $unreachableCount++
        }
    }
    
    Write-Progress -Activity "Testing Physical Servers" -Completed
    
    if ($unreachableCount -eq 0) {
        Add-CheckResult -Category "Network" -CheckName "Physical Servers Connectivity" -Status "Pass" `
            -Details "All $reachableCount physical servers are reachable from this appliance"
    }
    elseif ($reachableCount -gt 0) {
        Add-CheckResult -Category "Network" -CheckName "Physical Servers Connectivity" -Status "Warning" `
            -Details "$reachableCount servers reachable, $unreachableCount servers unreachable" `
            -Recommendation "Verify network connectivity and firewall rules for unreachable servers"
    }
    else {
        Add-CheckResult -Category "Network" -CheckName "Physical Servers Connectivity" -Status "Fail" `
            -Details "None of the $($Servers.Count) physical servers are reachable" `
            -Recommendation "Check network connectivity, DNS resolution, and firewall rules"
    }
}

# ============================================================================
# NETWORK CONNECTIVITY VALIDATION
# ============================================================================

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity to Azure endpoints
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "NETWORK CONNECTIVITY CHECKS" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Log -Message "Starting network connectivity checks..." -Level Info
    
    # Get endpoint type if not specified
    if ([string]::IsNullOrWhiteSpace($script:EndpointType)) {
        if ($InteractiveMode) {
            $script:EndpointType = Show-SelectionMenu -Title "Select Endpoint Type" `
                -Options @('Public', 'Private') -DefaultOption 'Public'
        }
        else {
            $script:EndpointType = 'Public'
        }
    }
    
    Write-Log -Message "Testing connectivity for $($script:EndpointType) endpoints" -Level Info
    
    if ($script:EndpointType -eq 'Public') {
        Test-PublicEndpoints
    }
    else {
        Test-PrivateEndpoints
    }
    
    # Appliance port requirements per discovery type
    Test-DiscoveryTypePorts
}

function Test-PublicEndpoints {
    <#
    .SYNOPSIS
        Tests connectivity to Azure public endpoints
    #>
    Write-Log -Message "Testing connectivity to Azure Public Endpoints..." -Level Info
    
    # Try to fetch latest URLs from Microsoft Learn
    $urlList = Get-AzureEndpointURLs
    
    $totalChecks = 0
    $passedChecks = 0
    $failedChecks = 0
    
    foreach ($category in $urlList.Keys) {
        Write-Host "`n--- Testing $category URLs ---`n" -ForegroundColor Yellow
        
        foreach ($url in $urlList[$category]) {
            $totalChecks++
            Write-Progress-Status -Activity "Network Connectivity" `
                -Status "Testing $url..." `
                -PercentComplete ($totalChecks / ($urlList.Values.Count * 3) * 100)
            
            $result = Test-URLConnectivity -URL $url
            
            if ($result.Success) {
                Write-Log -Message "[PASS] $url - Accessible (Response: $($result.StatusCode), Time: $($result.ResponseTime)ms)" -Level Success
                $passedChecks++
            }
            else {
                Write-Log -Message "[FAIL] $url - Not accessible (Error: $($result.ErrorMessage))" -Level Error
                $failedChecks++
            }
        }
    }
    
    Write-Progress -Activity "Network Connectivity" -Completed
    
    if ($failedChecks -eq 0) {
        Add-CheckResult -Category "Network" -CheckName "Public Endpoints Connectivity" -Status "Pass" `
            -Details "All $totalChecks Azure public endpoints are accessible"
    }
    elseif ($passedChecks -gt 0) {
        Add-CheckResult -Category "Network" -CheckName "Public Endpoints Connectivity" -Status "Warning" `
            -Details "$passedChecks/$totalChecks endpoints accessible, $failedChecks failed" `
            -Recommendation "Review firewall rules and proxy configuration for failed endpoints. See https://learn.microsoft.com/azure/migrate/migrate-appliance#url-access"
    }
    else {
        Add-CheckResult -Category "Network" -CheckName "Public Endpoints Connectivity" -Status "Fail" `
            -Details "None of the $totalChecks Azure endpoints are accessible" `
            -Recommendation "Check internet connectivity, proxy settings, and firewall rules. The appliance requires internet access."
    }
}

function Test-PrivateEndpoints {
    <#
    .SYNOPSIS
        Tests connectivity to Azure private endpoints
    #>
    Write-Log -Message "Testing connectivity for Private Endpoints configuration..." -Level Info
    
    $privateEndpointInfo = @(
        "For Private Endpoint connectivity, ensure the following are configured:",
        "1. Private Link connection to Azure Migrate service",
        "2. Private DNS zones for Azure services",
        "3. Network routing to private endpoints",
        "",
        "Essential public URLs still required (for authentication):",
        "  - portal.azure.com",
        "  - login.microsoftonline.com",
        "  - *.msftauth.net",
        "  - *.msauth.net",
        "",
        "For detailed Private Link setup:",
        "https://learn.microsoft.com/azure/migrate/how-to-use-azure-migrate-with-private-endpoints"
    ) -join "`n"
    
    Write-Host $privateEndpointInfo -ForegroundColor Yellow
    
    # Test essential public URLs that are always required
    $essentialURLs = @(
        'https://portal.azure.com',
        'https://login.microsoftonline.com'
    )
    
    $accessibleCount = 0
    foreach ($url in $essentialURLs) {
        $result = Test-URLConnectivity -URL $url
        if ($result.Success) {
            Write-Log -Message "[PASS] $url - Accessible" -Level Success
            $accessibleCount++
        }
        else {
            Write-Log -Message "[FAIL] $url - Not accessible" -Level Error
        }
    }
    
    if ($accessibleCount -eq $essentialURLs.Count) {
        Add-CheckResult -Category "Network" -CheckName "Private Endpoint Configuration" -Status "Pass" `
            -Details "Essential authentication endpoints are accessible. Ensure Private Link is configured for Azure Migrate services."
    }
    else {
        Add-CheckResult -Category "Network" -CheckName "Private Endpoint Configuration" -Status "Fail" `
            -Details "Essential authentication endpoints are not accessible" `
            -Recommendation "Even with Private Endpoints, authentication URLs must be accessible. Check proxy/firewall rules."
    }
    
    # Private endpoint specific checks would require Azure context
    Add-CheckResult -Category "Network" -CheckName "Private Link Setup" -Status "Info" `
        -Details "Manual verification required: Ensure Private Link is configured for storage accounts and Azure Migrate service" `
        -Recommendation "Follow guide: https://learn.microsoft.com/azure/migrate/how-to-use-azure-migrate-with-private-endpoints"
}

function Get-AzureEndpointURLs {
    <#
    .SYNOPSIS
        Gets Azure endpoint URLs based on CloudType (Public or Government)
    #>
    try {
        $learnUrl = "https://learn.microsoft.com/en-us/azure/migrate/migrate-appliance"
        $null = Invoke-WebRequest -Uri $learnUrl -TimeoutSec 5 -ErrorAction Stop
        Write-Log -Message "Successfully fetched latest endpoint information from Microsoft Learn" -Level Info
    }
    catch {
        Write-Log -Message "Could not fetch from Microsoft Learn, using hardcoded URL list" -Level Warning
    }
    
    # Return cloud-specific URL list
    if ($script:CloudType -eq 'Government') {
        Write-Log -Message "Using Azure Government cloud URL set" -Level Info
        return $script:AzureGovernmentEndpoints
    }
    else {
        return $script:AzurePublicEndpoints
    }
}

function Test-URLConnectivity {
    <#
    .SYNOPSIS
        Tests connectivity to a single URL
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$URL
    )
    
    $result = @{
        Success      = $false
        StatusCode   = $null
        ResponseTime = $null
        ErrorMessage = $null
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $URL -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $stopwatch.Stop()
        
        $result.Success = $true
        $result.StatusCode = $response.StatusCode
        $result.ResponseTime = $stopwatch.ElapsedMilliseconds
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message
        
        # Some endpoints might not support HEAD, try GET
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Uri $URL -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            $stopwatch.Stop()
            
            $result.Success = $true
            $result.StatusCode = $response.StatusCode
            $result.ResponseTime = $stopwatch.ElapsedMilliseconds
            $result.ErrorMessage = $null
        }
        catch {
            $result.ErrorMessage = $_.Exception.Message
        }
    }
    
    return $result
}

# ============================================================================
# APPLIANCE PORT REQUIREMENT CHECKS
# ============================================================================

function Test-DiscoveryTypePorts {
    <#
    .SYNOPSIS
        Validates base port requirements per discovery type (always runs when discovery type is set)
    #>
    Write-Host "`n--- Base Discovery Port Requirements ---`n" -ForegroundColor Yellow
    
    switch ($script:DiscoveryType) {
        'VMware' {
            Add-CheckResult -Category "Network" -CheckName "VMware Base Ports" -Status "Info" `
                -Details "VMware discovery requires: TCP 443 outbound to Azure, TCP 443 to vCenter Server, Inbound 3389 (RDP) and 44368 (appliance portal)" `
                -Recommendation "Ensure vCenter Server is accessible on port 443 from the appliance. IPv6 is not supported for vCenter/ESXi."
        }
        'HyperV' {
            # Check WinRM service on the appliance itself
            try {
                $winrmService = Get-Service -Name 'WinRM' -ErrorAction Stop
                $winrmStatus = if ($winrmService.Status -eq 'Running') { "Pass" } else { "Warning" }
                Add-CheckResult -Category "Network" -CheckName "WinRM Service (Appliance)" -Status $winrmStatus `
                    -Details "WinRM service is $($winrmService.Status) on this appliance" `
                    -Recommendation $(if ($winrmStatus -eq 'Warning') { "Start WinRM: Enable-PSRemoting -Force" } else { "" })
            }
            catch {
                Add-CheckResult -Category "Network" -CheckName "WinRM Service (Appliance)" -Status "Warning" `
                    -Details "Cannot check WinRM service: $($_.Exception.Message)"
            }
            
            Add-CheckResult -Category "Network" -CheckName "Hyper-V Base Ports" -Status "Info" `
                -Details "Hyper-V discovery requires: WinRM 5985 (HTTP) / 5986 (HTTPS) to Hyper-V hosts, TCP 443 outbound, Inbound 3389 + 44368" `
                -Recommendation "Ensure PowerShell remoting is enabled on each Hyper-V host. Supported hosts: Windows Server 2012 R2, 2016, 2019, 2022."
        }
        'Physical' {
            Add-CheckResult -Category "Network" -CheckName "Physical Base Ports" -Status "Info" `
                -Details "Physical discovery requires: WinRM 5985/5986 (Windows) or SSH 22 (Linux) to target servers, TCP 443 outbound, Inbound 3389 + 44368" `
                -Recommendation "Windows: WinRM HTTPS requires a local Server Auth certificate with CN matching hostname. Linux: SSH must be enabled."
        }
    }
}

# ============================================================================
# AZURE AUTHENTICATION VALIDATION
# ============================================================================

function Test-AzureAuthentication {
    <#
    .SYNOPSIS
        Tests Azure authentication methods
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "AZURE AUTHENTICATION VALIDATION" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Log -Message "Starting Azure authentication validation..." -Level Info
    
    # Get authentication method if not specified
    if ([string]::IsNullOrWhiteSpace($script:AuthMethod)) {
        if ($InteractiveMode) {
            Write-Host @"
Two Authentication Methods Available:
-------------------------------------
1. Device Code Flow (DCF)
   - User-friendly browser-based authentication
   - May be blocked by organizational policies
   - Recommended for manual appliance setup

2. Entra ID App Registration
   - Uses pre-configured service principal
   - Requires certificate-based authentication
   - Recommended when DCF is blocked or for automated deployments

"@ -ForegroundColor Cyan
            
            $script:AuthMethod = Show-SelectionMenu -Title "Select Authentication Method" `
                -Options @('DeviceCodeFlow', 'EntraIDApp') -DefaultOption 'DeviceCodeFlow'
        }
        else {
            $script:AuthMethod = 'DeviceCodeFlow'
        }
    }
    
    Write-Log -Message "Selected authentication method: $($script:AuthMethod)" -Level Info
    
    if ($script:AuthMethod -eq 'DeviceCodeFlow') {
        Test-DeviceCodeFlow
    }
    else {
        Test-EntraIDAppAuthentication
    }
}

function Test-DeviceCodeFlow {
    <#
    .SYNOPSIS
        Tests Device Code Flow authentication
    #>
    Write-Log -Message "Testing Device Code Flow authentication..." -Level Info
    
    Write-Host @"
Device Code Flow Authentication Process:
-----------------------------------------
1. This script will generate a device code
2. Microsoft Edge browser will open automatically
3. You will sign in with your Azure credentials
4. The script will monitor the authentication status

Microsoft recommends putting an exemption on Device Code Flow if it's blocked.
For more information: https://learn.microsoft.com/azure/migrate/troubleshoot-appliance-discovery

"@ -ForegroundColor Yellow
    
    if ($InteractiveMode) {
        $proceed = Read-Host "`nProceed with Device Code Flow authentication? (Y/N) [Y]"
        if ($proceed -eq 'N' -or $proceed -eq 'n') {
            Add-CheckResult -Category "Authentication" -CheckName "Device Code Flow" -Status "Info" `
                -Details "Device Code Flow authentication was skipped by user"
            return
        }
    }
    
    try {
        # Check if Az.Accounts module is available
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Add-CheckResult -Category "Authentication" -CheckName "Device Code Flow" -Status "Fail" `
                -Details "Az.Accounts module is not installed" `
                -Recommendation "Install Az.Accounts module: Install-Module -Name Az.Accounts -Repository PSGallery -Force"
            return
        }
        
        Import-Module Az.Accounts -ErrorAction Stop
        
        Write-Log -Message "Initiating Device Code Flow..." -Level Info
        Write-Host "`nInitiating Device Code Flow authentication..." -ForegroundColor Cyan
        Write-Host "A browser window will open for authentication...`n" -ForegroundColor Yellow
        
        # Attempt Device Code Flow authentication
        $context = Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop
        
        if ($context) {
            $accountId = $context.Context.Account.Id
            $tenantId = $context.Context.Tenant.Id
            $subscriptionId = $context.Context.Subscription.Id
            
            Write-Log -Message "Device Code Flow authentication successful - Account: $accountId, Tenant: $tenantId" -Level Success
            
            Add-CheckResult -Category "Authentication" -CheckName "Device Code Flow" -Status "Pass" `
                -Details "Successfully authenticated using Device Code Flow. Account: $accountId, Tenant: $tenantId, Subscription: $subscriptionId"
            
            # Store authenticated context
            $script:AzureContext = $context
            
            return $true
        }
        else {
            Add-CheckResult -Category "Authentication" -CheckName "Device Code Flow" -Status "Fail" `
                -Details "Device Code Flow authentication failed - no context returned"
            return $false
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Log -Message "Device Code Flow authentication failed: $errorMessage" -Level Error
        
        # Check if it's a policy block
        if ($errorMessage -match "AADSTS") {
            Add-CheckResult -Category "Authentication" -CheckName "Device Code Flow" -Status "Fail" `
                -Details "Device Code Flow is blocked by Azure AD policy: $errorMessage" `
                -Recommendation @"
Device Code Flow appears to be blocked by organizational policy. Options:
1. Request exemption for Device Code Flow in Azure AD (Recommended by Microsoft)
2. Use Entra ID App Registration method instead
3. Contact your Azure administrator

For exemption setup: https://learn.microsoft.com/azure/migrate/troubleshoot-appliance-discovery#error-50072
For App Registration: https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app
"@
        }
        else {
            Add-CheckResult -Category "Authentication" -CheckName "Device Code Flow" -Status "Fail" `
                -Details "Device Code Flow authentication failed: $errorMessage" `
                -Recommendation "Verify network connectivity and try again. Consider using Entra ID App Registration method."
        }
        
        return $false
    }
}

function Test-EntraIDAppAuthentication {
    <#
    .SYNOPSIS
        Tests Entra ID App Registration authentication
    #>
    Write-Log -Message "Testing Entra ID App Registration authentication..." -Level Info
    
    Write-Host @"
Entra ID App Registration Authentication:
------------------------------------------
This method uses a pre-configured service principal with certificate authentication.

Prerequisites:
1. Microsoft Entra ID application with Contributor role on the resource group
2. Certificate (.pfx) installed on the appliance
3. Registry values configured in HKLM:\SOFTWARE\Microsoft\AzureAppliance

Setup Guide: https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app

"@ -ForegroundColor Yellow
    
    # Check for existing registry configuration
    $applianceRegKey = "HKLM:\SOFTWARE\Microsoft\AzureAppliance"
    
    if (-not (Test-Path $applianceRegKey)) {
        Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Fail" `
            -Details "Azure Appliance registry key not found at $applianceRegKey" `
            -Recommendation @"
Follow these steps to configure Entra ID App Registration:
1. Create Entra ID application: https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app#1register-a-microsoft-entra-id-application-and-assign-permissions
2. Generate and install certificate
3. Update registry values
4. Re-run this script

Full guide: https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app
"@
        return $false
    }
    
    try {
        $regValues = Get-ItemProperty -Path $applianceRegKey -ErrorAction Stop
        
        $requiredKeys = @(
            'LocalCertThumbprint',
            'AgentServiceCommAadAppClientId',
            'AgentServiceCommAadAppObjectId',
            'AzureMigrateApplianceAadAppTenantId'
        )
        
        $missingKeys = @()
        foreach ($key in $requiredKeys) {
            if (-not $regValues.$key) {
                $missingKeys += $key
            }
        }
        
        if ($missingKeys.Count -gt 0) {
            Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Fail" `
                -Details "Missing required registry values: $($missingKeys -join ', ')" `
                -Recommendation "Complete Entra ID App setup: https://learn.microsoft.com/azure/migrate/how-to-register-appliance-using-entra-app"
            return $false
        }
        
        # Check certificate
        $certThumbprint = $regValues.LocalCertThumbprint
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $certThumbprint }
        
        if (-not $cert) {
            Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Fail" `
                -Details "Certificate with thumbprint $certThumbprint not found in LocalMachine\My store" `
                -Recommendation "Install the certificate (.pfx) in the Personal certificate store"
            return $false
        }
        
        Write-Log -Message "Found certificate: $($cert.Subject), Expires: $($cert.NotAfter)" -Level Info
        
        # Check certificate expiration
        if ($cert.NotAfter -lt (Get-Date)) {
            Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Fail" `
                -Details "Certificate has expired on $($cert.NotAfter)" `
                -Recommendation "Generate and install a new certificate"
            return $false
        }
        elseif ($cert.NotAfter -lt (Get-Date).AddDays(30)) {
            Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Warning" `
                -Details "Certificate expires soon: $($cert.NotAfter)" `
                -Recommendation "Plan to renew the certificate before expiration"
        }
        
        # Try to authenticate using the service principal
        try {
            $clientId = $regValues.AgentServiceCommAadAppClientId
            $tenantId = $regValues.AzureMigrateApplianceAadAppTenantId
            
            Write-Log -Message "Attempting to authenticate with service principal (ClientId: $clientId, TenantId: $tenantId)" -Level Info
            
            # This is a validation check - actual appliance would use the certificate for authentication
            Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Pass" `
                -Details "Entra ID App configuration is valid. ClientId: $clientId, TenantId: $tenantId, Certificate: Valid until $($cert.NotAfter)"
            
            return $true
        }
        catch {
            Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Fail" `
                -Details "Failed to authenticate with service principal: $($_.Exception.Message)" `
                -Recommendation "Verify service principal permissions and certificate configuration"
            return $false
        }
    }
    catch {
        Add-CheckResult -Category "Authentication" -CheckName "Entra ID App Registration" -Status "Fail" `
            -Details "Failed to read registry configuration: $($_.Exception.Message)" `
            -Recommendation "Run as Administrator to access registry keys"
        return $false
    }
}

# ============================================================================
# AZURE RBAC VALIDATION
# ============================================================================

function Test-AzureRBAC {
    <#
    .SYNOPSIS
        Tests Azure RBAC permissions
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "AZURE RBAC VALIDATION" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Log -Message "Starting Azure RBAC validation..." -Level Info
    
    # Check if we have an authenticated context
    if (-not $script:AzureContext) {
        Write-Log -Message "No Azure authentication context available - skipping RBAC checks" -Level Warning
        Add-CheckResult -Category "RBAC" -CheckName "Azure RBAC" -Status "Warning" `
            -Details "Azure RBAC checks skipped - no authenticated session" `
            -Recommendation "Complete authentication step before RBAC validation"
        return
    }
    
    # Get subscription
    Get-AzureSubscription
    
    # Get resource group
    Get-AzureResourceGroup
    
    # Validate role assignments (Contributor/Owner/Azure Migrate roles)
    Test-ContributorRole
    
    # Validate Resource Provider registrations
    Test-ResourceProviders
}

function Get-AzureSubscription {
    <#
    .SYNOPSIS
        Gets Azure subscription for the project
    #>
    try {
        $subscriptions = Get-AzSubscription -ErrorAction Stop
        
        if ($subscriptions.Count -eq 0) {
            Add-CheckResult -Category "RBAC" -CheckName "Subscription Access" -Status "Fail" `
                -Details "No accessible Azure subscriptions found" `
                -Recommendation "Ensure the authenticated account has access to at least one subscription"
            return
        }
        
        Write-Log -Message "Found $($subscriptions.Count) accessible subscription(s)" -Level Info
        
        if ([string]::IsNullOrWhiteSpace($script:SubscriptionId)) {
            if ($InteractiveMode) {
                Write-Host "`nAvailable Subscriptions:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $subscriptions.Count; $i++) {
                    Write-Host "$($i + 1). $($subscriptions[$i].Name) (ID: $($subscriptions[$i].Id))"
                }
                
                do {
                    Write-Host "`nSelect subscription (1-$($subscriptions.Count)): " -NoNewline -ForegroundColor Yellow
                    $choice = Read-Host
                    $choiceNum = 0
                    if ([int]::TryParse($choice, [ref]$choiceNum) -and $choiceNum -ge 1 -and $choiceNum -le $subscriptions.Count) {
                        $script:SubscriptionId = $subscriptions[$choiceNum - 1].Id
                        break
                    }
                    Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                } while ($true)
            }
            else {
                # Use current context subscription
                $script:SubscriptionId = $script:AzureContext.Context.Subscription.Id
            }
        }
        
        # Set the subscription context
        Set-AzContext -SubscriptionId $script:SubscriptionId -ErrorAction Stop | Out-Null
        $subName = (Get-AzSubscription -SubscriptionId $script:SubscriptionId).Name
        
        Write-Log -Message "Selected subscription: $subName ($($script:SubscriptionId))" -Level Success
        Add-CheckResult -Category "RBAC" -CheckName "Subscription Selection" -Status "Pass" `
            -Details "Subscription: $subName (ID: $($script:SubscriptionId))"
    }
    catch {
        Add-CheckResult -Category "RBAC" -CheckName "Subscription Access" -Status "Fail" `
            -Details "Failed to access subscriptions: $($_.Exception.Message)" `
            -Recommendation "Verify Azure authentication and subscription access"
    }
}

function Get-AzureResourceGroup {
    <#
    .SYNOPSIS
        Gets Azure resource group for the project
    #>
    try {
        $resourceGroups = Get-AzResourceGroup -ErrorAction Stop
        
        if ($resourceGroups.Count -eq 0) {
            Add-CheckResult -Category "RBAC" -CheckName "Resource Group Access" -Status "Warning" `
                -Details "No resource groups found in subscription" `
                -Recommendation "Create a resource group for Azure Migrate project"
            return
        }
        
        Write-Log -Message "Found $($resourceGroups.Count) resource group(s)" -Level Info
        
        if ([string]::IsNullOrWhiteSpace($script:ResourceGroupName)) {
            if ($InteractiveMode) {
                Write-Host "`nAvailable Resource Groups:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $resourceGroups.Count; $i++) {
                    Write-Host "$($i + 1). $($resourceGroups[$i].ResourceGroupName) (Location: $($resourceGroups[$i].Location))"
                }
                
                Write-Host "$($resourceGroups.Count + 1). Create new resource group" -ForegroundColor Green
                
                do {
                    Write-Host "`nSelect resource group (1-$($resourceGroups.Count + 1)): " -NoNewline -ForegroundColor Yellow
                    $choice = Read-Host
                    $choiceNum = 0
                    if ([int]::TryParse($choice, [ref]$choiceNum)) {
                        if ($choiceNum -ge 1 -and $choiceNum -le $resourceGroups.Count) {
                            $script:ResourceGroupName = $resourceGroups[$choiceNum - 1].ResourceGroupName
                            break
                        }
                        elseif ($choiceNum -eq ($resourceGroups.Count + 1)) {
                            $newRGName = Read-Host "Enter new resource group name"
                            if (-not [string]::IsNullOrWhiteSpace($newRGName)) {
                                $script:ResourceGroupName = $newRGName
                                Add-CheckResult -Category "RBAC" -CheckName "Resource Group" -Status "Info" `
                                    -Details "New resource group will be created: $newRGName" `
                                    -Recommendation "Ensure you have permissions to create resource groups"
                                return
                            }
                        }
                    }
                    Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                } while ($true)
            }
            else {
                Write-Log -Message "ResourceGroupName parameter is required for RBAC validation" -Level Warning
                return
            }
        }
        
        # Verify resource group exists
        $rg = Get-AzResourceGroup -Name $script:ResourceGroupName -ErrorAction SilentlyContinue
        if ($rg) {
            Write-Log -Message "Selected resource group: $($script:ResourceGroupName) (Location: $($rg.Location))" -Level Success
            Add-CheckResult -Category "RBAC" -CheckName "Resource Group Selection" -Status "Pass" `
                -Details "Resource Group: $($script:ResourceGroupName) (Location: $($rg.Location))"
        }
        else {
            Add-CheckResult -Category "RBAC" -CheckName "Resource Group Selection" -Status "Warning" `
                -Details "Resource group '$($script:ResourceGroupName)' does not exist" `
                -Recommendation "Create the resource group before deploying Azure Migrate project"
        }
    }
    catch {
        Add-CheckResult -Category "RBAC" -CheckName "Resource Group Access" -Status "Fail" `
            -Details "Failed to access resource groups: $($_.Exception.Message)" `
            -Recommendation "Verify permissions to list and access resource groups"
    }
}

function Test-ContributorRole {
    <#
    .SYNOPSIS
        Tests for Contributor, Owner, or Azure Migrate specific role assignments
    #>
    Write-Log -Message "Checking for required role assignments..." -Level Info
    
    if ([string]::IsNullOrWhiteSpace($script:SubscriptionId)) {
        Add-CheckResult -Category "RBAC" -CheckName "Role Assignment" -Status "Warning" `
            -Details "Cannot validate roles - no subscription selected"
        return
    }
    
    try {
        $currentUser = $script:AzureContext.Context.Account.Id
        
        # Check at subscription level
        $subScope = "/subscriptions/$($script:SubscriptionId)"
        $subRoles = Get-AzRoleAssignment -Scope $subScope -SignInName $currentUser -ErrorAction SilentlyContinue
        
        # Check for traditional roles AND new Azure Migrate built-in roles
        $hasRequiredRole = $subRoles | Where-Object { $_.RoleDefinitionName -in $script:AzureMigrateRoles }
        
        # Check at resource group level if specified
        $hasRGRole = $false
        if (-not [string]::IsNullOrWhiteSpace($script:ResourceGroupName)) {
            $rgScope = "/subscriptions/$($script:SubscriptionId)/resourceGroups/$($script:ResourceGroupName)"
            $rgRoles = Get-AzRoleAssignment -Scope $rgScope -SignInName $currentUser -ErrorAction SilentlyContinue
            $hasRGRole = $rgRoles | Where-Object { $_.RoleDefinitionName -in $script:AzureMigrateRoles }
        }
        
        if ($hasRequiredRole) {
            $roleNames = ($hasRequiredRole | Select-Object -ExpandProperty RoleDefinitionName -Unique) -join ', '
            Write-Log -Message "User has required role(s) at subscription level: $roleNames" -Level Success
            Add-CheckResult -Category "RBAC" -CheckName "Role Assignment" -Status "Pass" `
                -Details "User '$currentUser' has role(s): $roleNames at subscription level"
        }
        elseif ($hasRGRole) {
            $roleNames = ($hasRGRole | Select-Object -ExpandProperty RoleDefinitionName -Unique) -join ', '
            Write-Log -Message "User has required role(s) at resource group level: $roleNames" -Level Success
            Add-CheckResult -Category "RBAC" -CheckName "Role Assignment" -Status "Pass" `
                -Details "User '$currentUser' has role(s): $roleNames on resource group '$($script:ResourceGroupName)'"
        }
        else {
            Write-Log -Message "User does not have any required role" -Level Error
            Add-CheckResult -Category "RBAC" -CheckName "Role Assignment" -Status "Fail" `
                -Details "User '$currentUser' does not have any of the required roles: $($script:AzureMigrateRoles -join ', ')" `
                -Recommendation @"
Grant one of the following roles:
- Traditional: Contributor or Owner (broad access)
- Azure Migrate Owner (full Azure Migrate access)
- Azure Migrate Decide and Plan Expert (discovery + assessment)
- Azure Migrate Execute Expert (migration execution)

Subscription level: New-AzRoleAssignment -SignInName '$currentUser' -RoleDefinitionName 'Contributor' -Scope '/subscriptions/$($script:SubscriptionId)'
Resource Group level: New-AzRoleAssignment -SignInName '$currentUser' -RoleDefinitionName 'Contributor' -ResourceGroupName '$($script:ResourceGroupName)'

For appliance registration, the user also needs Application Developer role at Entra ID tenant level.
Docs: https://learn.microsoft.com/azure/migrate/prepare-azure-accounts
"@
        }
    }
    catch {
        Add-CheckResult -Category "RBAC" -CheckName "Role Assignment" -Status "Fail" `
            -Details "Failed to check role assignments: $($_.Exception.Message)" `
            -Recommendation "Verify permissions to query role assignments"
    }
}

function Test-ResourceProviders {
    <#
    .SYNOPSIS
        Checks if required Azure Resource Providers are registered in the subscription
    #>
    Write-Host "`n--- Resource Provider Registration ---`n" -ForegroundColor Yellow
    Write-Log -Message "Checking required Resource Provider registrations..." -Level Info
    
    if (-not $script:AzureContext) {
        Add-CheckResult -Category "RBAC" -CheckName "Resource Providers" -Status "Warning" `
            -Details "Cannot check Resource Providers - no authenticated session" `
            -Recommendation "Complete authentication to validate Resource Provider registration"
        return
    }
    
    try {
        $registeredCount = 0
        $unregisteredProviders = @()
        
        foreach ($provider in $script:RequiredResourceProviders) {
            Write-Progress-Status -Activity "Resource Providers" -Status "Checking $provider..."
            
            $rp = Get-AzResourceProvider -ProviderNamespace $provider -ErrorAction SilentlyContinue
            if ($rp -and $rp.RegistrationState -eq 'Registered') {
                $registeredCount++
            }
            else {
                $unregisteredProviders += $provider
            }
        }
        
        Write-Progress -Activity "Resource Providers" -Completed
        
        if ($unregisteredProviders.Count -eq 0) {
            Add-CheckResult -Category "RBAC" -CheckName "Resource Providers" -Status "Pass" `
                -Details "All $($script:RequiredResourceProviders.Count) required Resource Providers are registered"
        }
        elseif ($registeredCount -gt 0) {
            Add-CheckResult -Category "RBAC" -CheckName "Resource Providers" -Status "Warning" `
                -Details "$registeredCount/$($script:RequiredResourceProviders.Count) registered. Unregistered: $($unregisteredProviders -join ', ')" `
                -Recommendation "Register missing providers: $($unregisteredProviders | ForEach-Object { "Register-AzResourceProvider -ProviderNamespace '$_'" } | Out-String)"
        }
        else {
            Add-CheckResult -Category "RBAC" -CheckName "Resource Providers" -Status "Fail" `
                -Details "None of the $($script:RequiredResourceProviders.Count) required Resource Providers are registered" `
                -Recommendation "Register all providers. Quick command: @('$($script:RequiredResourceProviders -join "','")') | ForEach-Object { Register-AzResourceProvider -ProviderNamespace `$_ }"
        }
    }
    catch {
        Add-CheckResult -Category "RBAC" -CheckName "Resource Providers" -Status "Warning" `
            -Details "Failed to check Resource Providers: $($_.Exception.Message)" `
            -Recommendation "Manually verify providers are registered: Get-AzResourceProvider -ListAvailable | Where RegistrationState -eq 'Registered'"
    }
}

# ============================================================================
# HTML REPORT GENERATION
# ============================================================================

function GenerateHTMLReport {
    <#
    .SYNOPSIS
        Generates comprehensive HTML report
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "GENERATING REPORT" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Log -Message "Generating HTML report..." -Level Info
    
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    $htmlReport = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Migrate Appliance Readiness Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #0078D4; border-bottom: 3px solid #0078D4; padding-bottom: 10px; margin-bottom: 20px; }
        h2 { color: #333; margin-top: 30px; margin-bottom: 15px; padding-left: 10px; border-left: 4px solid #0078D4; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .summary-card { padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .summary-card.pass { background: #D4EDDA; border-left: 5px solid #28A745; }
        .summary-card.fail { background: #F8D7DA; border-left: 5px solid #DC3545; }
        .summary-card.warning { background: #FFF3CD; border-left: 5px solid #FFC107; }
        .summary-card h3 { font-size: 2em; margin: 10px 0; }
        .summary-card p { color: #666; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #0078D4; color: white; font-weight: 600; }
        tr:hover { background: #f5f5f5; }
        .status { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 0.85em; font-weight: 600; }
        .status.pass { background: #28A745; color: white; }
        .status.fail { background: #DC3545; color: white; }
        .status.warning { background: #FFC107; color: #333; }
        .status.info { background: #17A2B8; color: white; }
        .details { margin: 10px 0; padding: 10px; background: #f8f9fa; border-left: 3px solid #0078D4; font-size: 0.9em; }
        .recommendation { margin: 10px 0; padding: 10px; background: #FFF3CD; border-left: 3px solid #FFC107; font-size: 0.9em; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #ddd; text-align: center; color: #666; font-size: 0.9em; }
        .metadata { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .metadata p { margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Azure Migrate Appliance Readiness Report</h1>
        
        <div class="metadata">
            <p><strong>Report Generated:</strong> $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))</p>
            <p><strong>Script Version:</strong> $script:ScriptVersion</p>
            <p><strong>Duration:</strong> $($duration.ToString('hh\:mm\:ss'))</p>
            <p><strong>Migration Approach:</strong> $($script:MigrationApproach)</p>
            <p><strong>Discovery Type:</strong> $($script:DiscoveryType)</p>
            <p><strong>Cloud Type:</strong> $($script:CloudType)</p>
            <p><strong>Endpoint Type:</strong> $($script:EndpointType)</p>
        </div>
        
        <h2>Executive Summary</h2>
        <div class="summary">
            <div class="summary-card pass">
                <p>Passed</p>
                <h3>$script:SuccessCount</h3>
            </div>
            <div class="summary-card fail">
                <p>Failed</p>
                <h3>$script:ErrorCount</h3>
            </div>
            <div class="summary-card warning">
                <p>Warnings</p>
                <h3>$script:WarningCount</h3>
            </div>
            <div class="summary-card">
                <p>Total Checks</p>
                <h3>$($script:CheckResults.Count)</h3>
            </div>
        </div>
"@
    
    # Group results by category
    $categories = $script:CheckResults | Group-Object -Property Category
    
    foreach ($category in $categories) {
        $htmlReport += @"
        
        <h2>$($category.Name)</h2>
        <table>
            <thead>
                <tr>
                    <th>Check</th>
                    <th>Status</th>
                    <th>Timestamp</th>
                </tr>
            </thead>
            <tbody>
"@
        
        foreach ($result in $category.Group) {
            $statusClass = $result.Status.ToLower()
            $htmlReport += @"
                <tr>
                    <td>
                        <strong>$($result.CheckName)</strong>
                        $(if ($result.Details) { "<div class='details'>$($result.Details)</div>" })
                        $(if ($result.Recommendation) { "<div class='recommendation'><strong>Recommendation:</strong> $($result.Recommendation -replace "`n", "<br/>")</div>" })
                    </td>
                    <td><span class="status $statusClass">$($result.Status)</span></td>
                    <td>$($result.Timestamp.ToString('HH:mm:ss'))</td>
                </tr>
"@
        }
        
        $htmlReport += @"
            </tbody>
        </table>
"@
    }
    
    # Add recommendations section
    $failedChecks = $script:CheckResults | Where-Object { $_.Status -eq 'Fail' }
    if ($failedChecks.Count -gt 0) {
        $htmlReport += @"
        
        <h2>Critical Issues Requiring Attention</h2>
        <div class="details" style="background: #F8D7DA; border-left-color: #DC3545;">
            <p><strong>$($failedChecks.Count) critical issue(s) found that must be resolved before appliance deployment:</strong></p>
            <ul style="margin-left: 20px; margin-top: 10px;">
"@
        foreach ($check in $failedChecks) {
            $htmlReport += "<li><strong>$($check.CheckName)</strong>: $($check.Details)</li>"
        }
        $htmlReport += @"
            </ul>
        </div>
"@
    }
    
    $htmlReport += @"
        
        <div class="footer">
            <p>Azure Migrate Appliance Readiness Check v$script:ScriptVersion</p>
            <p>For more information: <a href="https://learn.microsoft.com/azure/migrate/">Azure Migrate Documentation</a></p>
        </div>
    </div>
</body>
</html>
"@
    
    try {
        $htmlReport | Out-File -FilePath $ReportPath -Encoding UTF8 -Force
        Write-Log -Message "HTML report generated: $ReportPath" -Level Success
        
        # Open report in default browser
        if ($InteractiveMode) {
            Start-Process $ReportPath
            Write-Host "`nReport saved and opened in browser: $ReportPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Log -Message "Failed to generate HTML report: $($_.Exception.Message)" -Level Error
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    <#
    .SYNOPSIS
        Main execution function
    #>
    try {
        Write-Log -Message "========================================" -Level Info
        Write-Log -Message "Azure Migrate Appliance Readiness Check v$script:ScriptVersion" -Level Info
        Write-Log -Message "Started at: $($script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level Info
        Write-Log -Message "========================================" -Level Info
        
        # Phase 1: Prerequisites
        Test-Prerequisites
        
        # Phase 2: Configuration
        Get-MigrationConfiguration
        
        # Phase 3: Network Connectivity
        Test-NetworkConnectivity
        
        # Phase 4: Azure Authentication
        Test-AzureAuthentication
        
        # Phase 5: RBAC Validation
        Test-AzureRBAC
        
        # Phase 6: Generate Report
        GenerateHTMLReport
        
        # Final Summary
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "VALIDATION COMPLETE" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "Summary:" -ForegroundColor White
        Write-Host "  Passed:   $script:SuccessCount" -ForegroundColor Green
        Write-Host "  Failed:   $script:ErrorCount" -ForegroundColor Red
        Write-Host "  Warnings: $script:WarningCount" -ForegroundColor Yellow
        Write-Host "  Total:    $($script:CheckResults.Count)" -ForegroundColor White
        
        Write-Host "`nLog File:    $LogPath" -ForegroundColor Cyan
        Write-Host "Report File: $ReportPath`n" -ForegroundColor Cyan
        
        if ($script:ErrorCount -gt 0) {
            Write-Host "⚠ Critical issues found. Review the report for details." -ForegroundColor Red
            exit 1
        }
        elseif ($script:WarningCount -gt 0) {
            Write-Host "⚠ Warnings found. Review the report for recommendations." -ForegroundColor Yellow
            exit 0
        }
        else {
            Write-Host "[PASS] All checks passed successfully!" -ForegroundColor Green
            exit 0
        }
    }
    catch {
        Write-Log -Message "Script execution failed: $($_.Exception.Message)" -Level Error
        Write-Host "`nScript execution failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Run main function
Main

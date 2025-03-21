param (
    [Parameter(Mandatory=$true)]
    [string]$Email,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$PfxPassword,

    [Parameter(Mandatory=$true)]
    [string]$ContactEmail,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$DnsZoneName
)

# Install the Posh-ACME module if not already installed
if (-not (Get-Module -ListAvailable -Name Posh-ACME)) {
    Install-Module -Name Posh-ACME -Scope CurrentUser -Force
}

# Import the Posh-ACME module
Import-Module Posh-ACME

# Set the Let's Encrypt server to use
Set-PAServer LE_STAGE

# Set the Posh-ACME configuration
$account = New-PAAccount -Contact $Email -AcceptTOS

# Configure the Azure DNS plugin parameters 
# Note: We don't need to pass credentials since we're using the GitHub Actions Azure login
$azContext = (az account show | ConvertFrom-Json)
$subscriptionId = $azContext.id
$tenantId = $azContext.tenantId

$spInfo = az ad signed-in-user show 2>$null | ConvertFrom-Json
if (-not $spInfo) {
    $spInfo = az ad sp show --id $env:AZURE_CLIENT_ID | ConvertFrom-Json
}
$clientId = $env:AZURE_CLIENT_ID

# Create a credential object
$securePassword = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($clientId, $securePassword)

# Configure the Azure DNS plugin parameters
$pluginParams = @{
    AZSubscriptionId = $subscriptionId
    AZTenantId = $tenantId
    AZResourceGroup = $ResourceGroupName
    AZZoneName = $DnsZoneName
    AZAppCred = $credential
}

Write-Output "AAAAAAAAAAAAAAAAAAAAAA"
Write-Output $pluginParams

Write-Output "Creating certificate for $Domain using Azure DNS for validation (STAGING ENVIRONMENT)"
$cert = New-PACertificate -Domain $Domain -DnsPlugin Azure -PluginArgs $pluginParams -PfxPass $PfxPassword -Verbose

Write-Output $cert
# Export the certificate to a PFX file
$certPath = "$Domain.pfx"
$cert.PfxBytes | Set-Content -Path $certPath -Encoding Byte

Write-Output "Certificate generated and saved to $certPath"

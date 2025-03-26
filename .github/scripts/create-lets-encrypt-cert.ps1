param (
    [Parameter(Mandatory=$true)]
    [string]$Email,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$ContactEmail,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$DnsZoneName,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$CertificateName,
    
    [int]$RenewalThresholdDays = 30
)

Write-Output "Starting certificate management process..."

# Install the Posh-ACME module if not already installed
if (-not (Get-Module -ListAvailable -Name Posh-ACME)) {
    Write-Output "Installing Posh-ACME module..."
    Install-Module -Name Posh-ACME -Scope CurrentUser -Force
}

# Import the Posh-ACME module
Import-Module Posh-ACME

Write-Output "Checking if certificate exists in Key Vault..."
$certExists = $false
$needsRenewal = $false

# Check if certificate exists in Key Vault
try {
    $certInfo = az keyvault certificate show --vault-name $KeyVaultName --name $CertificateName | ConvertFrom-Json
    if ($certInfo) {
        $certExists = $true
        
        # Get expiration date and determine if renewal is needed
        $expiryDate = [DateTime]$certInfo.attributes.expires
        $daysUntilExpiry = ($expiryDate - (Get-Date)).Days
        
        Write-Output "Certificate '$CertificateName' found in Key Vault."
        Write-Output "Certificate expires on: $expiryDate (in $daysUntilExpiry days)"
        
        if ($daysUntilExpiry -le $RenewalThresholdDays) {
            Write-Output "Certificate will expire within $RenewalThresholdDays days. Renewal needed."
            $needsRenewal = $true
        } else {
            Write-Output "Certificate is still valid for more than $RenewalThresholdDays days. No renewal needed."
        }
    }
} catch {
    Write-Output "Certificate not found in Key Vault or error checking: $_"
    $certExists = $false
}

# Set the Let's Encrypt server to use
Set-PAServer LE_STAGE

# Set the Posh-ACME configuration
$account = New-PAAccount -Contact $Email -AcceptTOS -EA SilentlyContinue
if (-not $account) {
    $account = Get-PAAccount
}

# Configure the Azure DNS plugin parameters
$azContext = (az account show | ConvertFrom-Json)
$subscriptionId = $azContext.id
$tenantId = $azContext.tenantId
$token = (az account get-access-token --resource 'https://management.core.windows.net/' | ConvertFrom-Json).accessToken

# Configure the Azure DNS plugin parameters
$pluginParams = @{
    AZSubscriptionId = $subscriptionId
    AZAccessToken = $token
}

# Generate a random password for the certificate
$password = -join ((65..90) + (97..122) + (48..57) + (33..47) | Get-Random -Count 16 | ForEach-Object {[char]$_})
# Mask the password in logs
Write-Output "::add-mask::$password"

if ($certExists -and -not $needsRenewal) {
    Write-Output "Certificate is up to date. No action needed."
} else {
    if ($certExists -and $needsRenewal) {
        # Check if we have an existing certificate order in Posh-ACME
        $existingOrder = Get-PAOrder -Domain $Domain -EA SilentlyContinue
        
        if ($existingOrder) {
            Write-Output "Renewing existing certificate for $Domain"
            $cert = Submit-Renewal -Domain $Domain -PfxPass $password -Verbose
        } else {
            Write-Output "No existing order found in Posh-ACME, creating new certificate for $Domain"
            $cert = New-PACertificate -Domain $Domain -DnsPlugin Azure -PluginArgs $pluginParams -PfxPass $password -Verbose
        }
    } else {
        Write-Output "Creating new certificate for $Domain"
        $cert = New-PACertificate -Domain $Domain -DnsPlugin Azure -PluginArgs $pluginParams -PfxPass $password -Verbose
    }

    if ($cert) {
        $pfxFullChainPath = $cert.PfxFullChain
        
        Write-Output "Importing certificate to Key Vault $KeyVaultName"
        az keyvault certificate import --vault-name $KeyVaultName --name $CertificateName --file $pfxFullChainPath --password $password
        az keyvault secret set --vault-name $KeyVaultName --name "$CertificateName-secret" --value $password

        Write-Output "Certificate successfully imported to Key Vault"
    } else {
        Write-Error "Failed to generate or renew certificate"
        exit 1
    }
}

Write-Output "Certificate management process completed"

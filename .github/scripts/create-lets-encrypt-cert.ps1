param (
    [Parameter(Mandatory=$true)]
    [string]$Email,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,

    [Parameter(Mandatory=$true)]
    [string]$DnsZoneName,
    
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

# Check if certificate exists in Key Vault and needs renewal
$certExists = $false
$needsRenewal = $false

$certificateName = "cert-" + ($DomainName -replace '\.', '-')
try {
    $certInfo = az keyvault certificate show --vault-name $KeyVaultName --name $certificateName | ConvertFrom-Json
    if ($certInfo) {
        $certExists = $true
        
        # Get expiration date and determine if renewal is needed
        $expiryDate = [DateTime]$certInfo.attributes.expires
        $daysUntilExpiry = ($expiryDate - (Get-Date)).Days
        
        Write-Output "Certificate '$certificateName' found in Key Vault."
        Write-Output "Certificate expires on: $expiryDate (in $daysUntilExpiry days)"
        
        if ($daysUntilExpiry -le $RenewalThresholdDays) {
            Write-Output "Certificate will expire within $RenewalThresholdDays days. Renewal needed."
            $needsRenewal = $true
        } else {
            Write-Output "Certificate is still valid for more than $RenewalThresholdDays days. No renewal needed."
            # Exit early if no renewal is needed
            Write-Output "No action needed. Exiting."
            exit 0
        }
    }
} catch {
    Write-Output "Certificate not found in Key Vault or error checking: $_"
    $certExists = $false
    $needsRenewal = $true  # If cert doesn't exist, we need to create it
}

# If we reached here, we either need to create a new certificate or renew an existing one
# Set the Let's Encrypt server to use
Set-PAServer LE_STAGE

# Create a new ACME account or use existing one
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
Write-Output "::add-mask::$password"
$password = -join ((65..90) + (97..122) + (48..57) + (33..47) | Get-Random -Count 16 | ForEach-Object {[char]$_})

# Since we're not tracking order state, always create a new certificate when needed
Write-Output "Creating new certificate for $Domain using Azure DNS for validation (STAGING ENVIRONMENT)"
$cert = New-PACertificate -Domain $Domain -DnsPlugin Azure -PluginArgs $pluginParams -PfxPass $password -Verbose

if ($cert) {
    $pfxFullChainPath = $cert.PfxFullChain
    
    Write-Output "Full Chain certificate generated for $Domain and saved to $pfxFullChainPath"
    Write-Output "Importing to Key Vault $KeyVaultName..."
    
    # Import the certificate to Key Vault
    $import_out = az keyvault certificate import --vault-name $KeyVaultName --name $certificateName --file $pfxFullChainPath --password $password --output none
    #az keyvault secret set --vault-name $KeyVaultName --name "$certificateName-secret" --value $password
    
    Write-Output "Certificate successfully imported to Key Vault"
} else {
    Write-Error "Failed to generate certificate"
    exit 1
}

# Wait longer for Azure to process the certificate
Write-Output "Waiting for Azure to process the new certificate..."
Start-Sleep -Seconds 60

# Get the latest certificate directly
$newCert = az keyvault certificate show --vault-name $KeyVaultName --name $certificateName | ConvertFrom-Json
$newCertThumbprint = $newCert.x509Thumbprint
$versionId = $newCert.id.Split('/')[-1]

Write-Output "New certificate thumbprint: $newCertThumbprint"
Write-Output "New certificate version ID: $versionId"

# Get all versions
$allVersions = az keyvault certificate list-versions --vault-name $KeyVaultName --name $certificateName | ConvertFrom-Json

# Debug output to see what's being returned
Write-Output "Found $($allVersions.Count) total certificate versions"
foreach ($v in $allVersions) {
    Write-Output "Certificate version: $($v.id.Split('/')[-1]), Created: $($v.attributes.created), Enabled: $($v.attributes.enabled), Thumbprint: $($v.x509Thumbprint)"
}

# Find and disable old versions that are ENABLED by comparing thumbprints
$oldVersions = $allVersions | Where-Object { 
    $_.x509Thumbprint -ne $newCertThumbprint -and $_.attributes.enabled -eq $true 
}

if ($oldVersions -and $oldVersions.Count -gt 0) {
    Write-Output "Found $($oldVersions.Count) older ENABLED versions to disable"
    
    foreach ($version in $oldVersions) {
        $versionId = $version.id.Split('/')[-1]
        Write-Output "Disabling cert with ID: $versionId, Thumbprint: $($version.x509Thumbprint)"
        az keyvault certificate set-attributes --vault-name $KeyVaultName --name $certificateName --version $versionId --enabled false --output none
    }
} else {
    Write-Output "No older enabled versions found to disable"
}

Write-Output "Certificate management process completed"

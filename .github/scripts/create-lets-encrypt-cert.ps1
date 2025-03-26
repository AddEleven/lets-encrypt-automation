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
    Write-Output "NOTTTTT ACCCOUNT"
    $account = Get-PAAccount
}

Write-Output $account

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
# Check if a certificate for this domain already exists
$existingOrder = $null
$allOrders = Get-PAOrder
Write-Output "EEEEEEEEEEEEEEEEEEEEEEEEEE"
Write-Output $allOrders

foreach ($order in $allOrders) {
    # Check the main name of the order
    if ($order.MainDomain -eq $Domain) {
        $existingOrder = $order
        break
    }
}

# if ($existingOrder) {
#     Write-Output "Found existing certificate for $Domain, checking if renewal is needed..."
    
#     # Select the existing order
#     Set-PAOrder -Order $existingOrder.OrderNumber
    
#     # Check if renewal is needed (30 days before expiry is a good practice)
#     $cert = Get-PACertificate
#     $expiryDate = $cert.NotAfter
#     $renewalDate = $expiryDate.AddDays(-30)
    
#     if ((Get-Date) -ge $renewalDate) {
#         Write-Output "Certificate expires on $expiryDate. Renewal needed."
#         # Submit renewal for the current order
#         $cert = Submit-Renewal -PfxPass $password -Verbose
#     } else {
#         Write-Output "Certificate still valid until $expiryDate. No renewal needed."
#         # We can still get the certificate data
#         $cert = Get-PACertificate
#     }
# } else {
#     Write-Output "Creating new certificate for $Domain using Azure DNS for validation (STAGING ENVIRONMENT)"
#     $cert = New-PACertificate -Domain $Domain -DnsPlugin Azure -PluginArgs $pluginParams -PfxPass $password -Verbose
# }

# Write-Output $cert
# # Export the certificate to a PFX file

# $pfxFullChainPath = $cert.PfxFullChain
# $certContent = Get-Content -Path $cert.FullChainFile -Raw

# Write-Output $certContent

# Write-Output "Full Chain certificate generated for $Domain and saved to $pfxFullChainPath"

# Write-Output "Importing to kv....."
# # First, mask the password value
# az keyvault certificate import --vault-name kv-adtest-001 --name blog-alexdantico-com --file $pfxFullChainPath --password $password
# az keyvault secret set --vault-name kv-adtest-001 --name blog-alexdantico-com-secret --value $password

# Write-Output "Done"

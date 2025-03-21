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

Write-Output "BBBBBBBBBBBB"
# Install the Posh-ACME module if not already installed
if (-not (Get-Module -ListAvailable -Name Posh-ACME)) {
    Install-Module -Name Posh-ACME -Scope CurrentUser -Force
}

# Import the Posh-ACME module
Import-Module Posh-ACME

Write-Output "CCCCCCCCCCCCCCCC"
# Set the Let's Encrypt server to use
Set-PAServer LE_STAGE

Write-Output "DDDDDDDDDDDDDDDDDDDDDD"
# Set the Posh-ACME configuration
$account = New-PAAccount -Contact $Email -AcceptTOS

Write-Output "EEEEEEEEEEEEEEEEEEEEEEEE"
# Configure the Azure DNS plugin parameters 
# Note: We don't need to pass credentials since we're using the GitHub Actions Azure login
$azContext = (az account show | ConvertFrom-Json)
$subscriptionId = $azContext.id
$tenantId = $azContext.tenantId

Write-Output "FFFFFFFFFFFFFFFFF"
$clientId = $env:AZURE_CLIENT_ID

Write-Output $clientId

Write-Output "GGGGGGGGGGGGGGGGGGGGGGGG"
az account list
$token = (az account get-access-token --resource 'https://management.core.windows.net/' | ConvertFrom-Json).accessToken

# Configure the Azure DNS plugin parameters
$pluginParams = @{
    AZSubscriptionId = $subscriptionId
    AZAccessToken = $token
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

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
    [string]$AzureTenantId,

    [Parameter(Mandatory=$true)]
    [string]$AzureClientId,

    [Parameter(Mandatory=$true)]
    [string]$AzureClientSecret,

    [Parameter(Mandatory=$true)]
    [string]$AzureSubscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$AzureResourceGroupName
)

# Install the Posh-ACME module if not already installed
if (-not (Get-Module -ListAvailable -Name Posh-ACME)) {
    Install-Module -Name Posh-ACME -Scope CurrentUser -Force
}

# Import the Posh-ACME module
Import-Module Posh-ACME

# Set the Posh-ACME configuration
Set-PAConfig -AcceptTOS -Contact $ContactEmail

# Initialize the ACME account
New-PAAccount -Contact $Email

# Set the DNS provider to Azure
$pluginArgs = @{
    TenantId        = $AzureTenantId
    ClientId        = $AzureClientId
    ClientSecret    = $AzureClientSecret
    SubscriptionId  = $AzureSubscriptionId
    ResourceGroupName = $AzureResourceGroupName
}

Set-PAOrder -DnsPlugin Azure -PluginArgs $pluginArgs

# Create a new order for the domain
New-PAOrder -Domain $Domain

# Complete the DNS challenge
Complete-PAChallenge -DnsPlugin Azure -PluginArgs $pluginArgs

# Wait for the challenge to be validated
while ((Get-PAOrder).Status -ne "valid") {
    Start-Sleep -Seconds 10
}

# Finalize the order and download the certificate
$cert = Get-PACertificate -ExportPkcs12 -PfxPass $PfxPassword

# Export the certificate to a PFX file
$certPath = "$Domain.pfx"
$cert | Out-File -FilePath $certPath -Encoding Byte

Write-Output "Certificate generated and saved to $certPath"

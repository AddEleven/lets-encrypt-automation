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
Set-PAServer LE_PROD

# Set the Posh-ACME configuration
$account = New-PAAccount -Contact $Email -AcceptTOS

# Configure the Azure DNS plugin parameters 
# Note: We don't need to pass credentials since we're using the GitHub Actions Azure login
$pluginParams = @{
    AZSubscriptionId = (Get-AzContext).Subscription.Id
    AZTenantId = (Get-AzContext).Tenant.Id
    AZResourceGroup = $ResourceGroupName
    AZZoneName = $DnsZoneName
}

# Create the certificate with DNS validation via Azure DNS
Write-Output "Creating certificate for $Domain using Azure DNS for validation"
$cert = New-PACertificate -Domain $Domain -DnsPlugin Azure -PluginArgs $pluginParams -PfxPass $PfxPassword -Verbose

# Export the certificate to a PFX file
$certPath = "$Domain.pfx"
$cert.PfxBytes | Set-Content -Path $certPath -Encoding Byte

Write-Output "Certificate generated and saved to $certPath"

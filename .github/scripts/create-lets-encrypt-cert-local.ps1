param (
    [Parameter(Mandatory=$true)]
    [string]$Email,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$PfxPassword,

    [Parameter(Mandatory=$true)]
    [string]$ContactEmail
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

Write-Output "AAAAAAAAAAAAAAAAAAAAAA"
Write-Output $pluginParams

Write-Output "Creating certificate for $Domain using Azure DNS for validation (STAGING ENVIRONMENT)"
$cert = New-PACertificate -Domain $Domain -PfxPass $PfxPassword -Verbose

Write-Output $cert
# Export the certificate to a PFX file

$pfxFullChainPath = $cert.PfxFullChain
$certContent = Get-Content -Path $cert.FullChainFile -Raw

Write-Output $certContent

Write-Output "Full Chain certificate generated fo $Domain and saved to $pfxFullChainPath"

Write-Output "::set-output name=cert_path::$pfxFullChainPath"

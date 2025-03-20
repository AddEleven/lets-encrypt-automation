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

# Install the Posh-ACME module if not already installed
if (-not (Get-Module -ListAvailable -Name Posh-ACME)) {
    Install-Module -Name Posh-ACME -Scope CurrentUser -Force
}

# Import the Posh-ACME module
Import-Module Posh-ACME

# Set the Posh-ACME configuration
$account = New-PAAccount -Contact $Email -AcceptTOS

# Finalize the order and download the certificate
$cert = New-PACertificate -Domain $Domain -PfxPass $PfxPassword

# Export the certificate to a PFX file
$certPath = "$Domain.pfx"
$cert.PfxBytes | Set-Content -Path $certPath -Encoding Byte

Write-Output "Certificate generated and saved to $certPath"

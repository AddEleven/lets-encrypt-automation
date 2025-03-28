 Azure Let's Encrypt Certificate Automation

[![Generate-Lets-Encrypt-Certificate](https://github.com/AddEleven/lets-encrypt-automation/actions/workflows/cert-mgmt.yml/badge.svg)](https://github.com/AddEleven/lets-encrypt-automation/actions/workflows/cert-mgmt.yml)

This repository contains an automated solution for creating, renewing, and managing Let's Encrypt SSL/TLS certificates using GitHub Actions and Azure services. The certificates are stored in Azure Key Vault for easy consumption by your Azure applications.

## Features

- 🔄 **Automated renewals** - Runs on the 1st and 15th of every month
- 🔒 **Secure storage** - Certificates stored in Azure Key Vault
- 🔍 **DNS validation** - Uses Azure DNS for domain ownership validation
- 🧪 **Testing support** - Optional staging environment for testing without rate limits
- 🔄 **Version management** - Automatically disables old certificate versions

## Prerequisites

### Azure Resources

You need the following Azure resources set up:

1. **Azure DNS Zone** - For domain validation
   - Must contain the domain you're generating certificates for
   - Example: `example.com` DNS Zone for `app.example.com` certificates

2. **Azure Key Vault** - For certificate storage
   - Must have sufficient access policies for the service principal

### GitHub Repository Configuration

#### Repository Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Azure service principal client ID |
| `AZURE_CLIENT_SECRET` | Azure service principal secret |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `LETS_ENCRYPT_EMAIL` | Email for Let's Encrypt registration |
| `KEY_VAULT_RESOURCE_NAME` | Name of your Azure Key Vault |

#### Repository Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Description |
|----------|-------------|
| `DOMAIN_NAME` | Domain for certificate (e.g., `app.example.com`) |
| `AZURE_DNS_ZONE_NAME` | Azure DNS Zone name (e.g., `example.com`) |

## Required Permissions

### Service Principal Permissions

The service principal used by GitHub Actions requires:

#### Key Vault Permissions
- **Certificates**: Get, List, Import, Update
- **Secrets**: Get, List, Set

#### DNS Zone Permissions
- **DNS Zone Contributor** - To create TXT records for domain validation

### GitHub Actions Permissions

The workflow uses the following permissions:
- `id-token: write` - For Azure login
- `contents: read` - For repository access

## How It Works

### Certificate Generation Process

1. **Workflow Trigger**
   - Runs on a schedule (1st and 15th of each month)
   - Can be triggered manually with optional staging parameter

2. **Certificate Check**
   - Checks if certificate exists in Key Vault
   - Calculates days until expiry
   - Skips renewal if more than 30 days left

3. **Certificate Generation**
   - Uses Posh-ACME to interact with Let's Encrypt
   - Uses Azure DNS for domain validation
   - Generates a PFX certificate

4. **Key Vault Storage**
   - Imports certificate to Key Vault with generated name: `cert-domain-name`
   - Example: `cert-app-example-com`

5. **Version Management**
   - Identifies the newly imported certificate
   - Disables all older versions of the certificate

### Workflow File

The GitHub Actions workflow (`generate-cert.yml`) handles:
- Scheduling certificate renewals
- Azure authentication
- Running the PowerShell script

### PowerShell Script

The PowerShell script (`create-lets-encrypt-cert.ps1`) handles:
- Checking for existing certificates
- Interacting with Let's Encrypt
- Managing certificate versions in Key Vault

## Usage

### Automatic Renewals

Certificates are automatically renewed when they're within 30 days of expiry. No action required.

### Manual Certificate Generation

1. Go to the "Actions" tab in your GitHub repository
2. Select "Generate-Lets-Encrypt-Certificate" workflow
3. Click "Run workflow"
4. Optionally select "Use Lets Encrypt staging environment" for testing
5. Click "Run workflow"

## Troubleshooting

### Common Issues

1. **DNS Validation Failures**
   - Ensure the service principal has DNS Zone Contributor permissions
   - Check that the DNS Zone matches the domain's parent zone

2. **Key Vault Access Issues**
   - Verify the service principal has proper Key Vault access policies
   - Check for "Access denied" errors in the workflow logs

3. **Rate Limit Errors**
   - Use the staging environment for testing to avoid hitting Let's Encrypt production rate limits
   - Ensure you're not requesting too many certificates for the same domain

### Debug Logging

The script outputs detailed information about:
- Certificate expiry dates
- Certificate versions and thumbprints
- Disabled certificate versions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

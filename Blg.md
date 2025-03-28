# Automating Let's Encrypt Certificate Management with GitHub Actions and Azure

I recently set up an Azure App Service with an Application Gateway frontend. Everything was working smoothly with Azure App Service managed certificates (Microsoft Docs) until I hit a major roadblock: you can't export these certificates, making them completely useless for integrating with Azure App Gateway's TLS requirements. 

Looking for alternatives, I investigated other Azure certificate solutions like Key Vault generated certificates (Microsoft Docs) and Azure App Service certificates (Microsoft Docs). Once I looked at the pricing and—being the frugal engineer that I am (read: cheap bastard)—I immediately started searching for more cost-effective options.

Enter Let's Encrypt: offering essentially the same security features as paid certificates, but completely free. The only downside? A slightly more complex management process. But that's exactly what led me to create this solution. In this post, I'll walk you through my certificate selection journey (spoiler alert: Let's Encrypt wins) and share the open-source automation solution I built to make the entire process painless.

## What My Solution Does

My repository provides a complete automation pipeline for Let's Encrypt certificates with these key features:

- **Fully automated renewals** running twice monthly
- **Azure Key Vault integration** for secure certificate storage
- **Azure DNS validation** for domain ownership verification
- **Version management** that disables old certificate versions
- **Testing capabilities** with optional staging environment support

The solution consists of a GitHub Actions workflow that runs on a schedule, and a PowerShell script utilizing Posh-ACME to handle certificate operations. It checks if certificates need renewal, handles the Let's Encrypt process, and manages storage in Azure Key Vault.

## Why Choose This Approach?

### Comparing with Other Azure Certificate Options

DV: Domain Validation - Verifies domain ownership only
OV: Organization Validation - Verifies organization information
EV: Extended Validation - Highest level of validation, shows organization name in browser

A common question: "Are Let's Encrypt certificates as secure as traditional CA certificates?"

**The short answer: Yes.**

Let's Encrypt certificates:
- Use the same 2048-bit RSA keys or ECC cryptography
- Follow the same validation standards
- Are recognized by all major browsers
- Comply with CA/Browser Forum requirements
- Are trusted in the same root certificate programs

The primary difference is the 90-day validity period (vs 1+ years for paid certificates), but shorter certificate lifetimes are actually considered a security best practice because they limit the impact of key compromise.

### Additional Benefits

1. **Infrastructure as Code:** The entire certificate process is in version-controlled code
2. **Audit Trail:** GitHub Actions provides logs of all certificate operations
3. **Reduced Operational Burden:** No more last-minute certificate renewals
4. **Consistent Process:** Same approach works across environments
5. **Scalability:** Easily manage certificates for dozens or hundreds of domains

## Future Enhancements

I'm planning to enhance this solution with Azure Storage for state management, which will add:
- Persistent tracking of ACME orders
- Certificate history for audit purposes
- Rate limit prevention mechanisms
- Cross-run consistency for edge cases


## Walkthrough of pipeline

## Conclusion

While Azure offers several certificate management options, this automated Let's Encrypt solution provides a compelling alternative that balances cost, flexibility, and security. It puts you in control of your certificate lifecycle while eliminating the operational overhead of manual renewals.

The security of Let's Encrypt certificates is on par with traditional CAs, making this automation a cost-effective way to maintain proper TLS/SSL security across your Azure ecosystem.

Feel free to check out the repository, contribute, or adapt it to your own needs. I'd love to hear how you're using it in your own environments!

---

*Have you built similar automation for your cloud infrastructure? What certificate management challenges have you faced? Let me know in the comments!*

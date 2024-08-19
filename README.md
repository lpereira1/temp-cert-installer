# Certificate Creation and Installation Script

This PowerShell script automates the process of creating a Root Certificate Authority (CA) and signing a certificate for a specified domain using OpenSSL. It then installs the Root CA as a trusted certificate and configures the signed certificate for use in IIS (Internet Information Services). Finally, the script cleans up all generated files and uninstalls OpenSSL.

## Prerequisites

- **PowerShell 5.1 or higher**: Ensure you are running PowerShell 5.1 or a later version.
- **Administrator Privileges**: The script requires administrative privileges to run.
- **Chocolatey**: The script installs OpenSSL using Chocolatey. If you don’t have Chocolatey installed, the script will install it automatically.

## Script Usage

### Parameters

| Parameter    | Description                                                                                   | Required | Default Value           |
|--------------|-----------------------------------------------------------------------------------------------|----------|-------------------------|
| `RootDomain` | The root domain for which the Root CA will be created (e.g., `codecraftednetwork.com`).      | Yes      |                         |
| `CertDomain` | The domain name for the certificate to be signed (e.g., `*.users.codecraftednetwork.com`).   | Yes      |                         |
| `Country`    | The country code for the certificate (e.g., `US`).                                            | No       | `US`                    |
| `State`      | The state or province for the certificate (e.g., `California`).                               | No       | `State`                 |
| `Locality`   | The city or locality for the certificate (e.g., `Los Angeles`).                               | No       | `City`                  |
| `Organization`| The organization name for the certificate (e.g., `MyCompany`).                               | No       | `Organization`          |
| `OrgUnit`    | The organizational unit for the certificate (e.g., `IT`).                                     | No       | `OrgUnit`               |
| `Email`      | The email address associated with the certificate (e.g., `admin@domain.com`).                 | No       | `admin@domain.com`      |

### Example Usage

```powershell
.\cert-installer.ps1 -RootDomain "codecraftednetwork.com" -CertDomain "*.users.codecraftednetwork.com" -Country "US" -State "California" -Locality "Los Angeles" -Organization "MyCompany" -OrgUnit "IT" -Email "admin@codecraftednetwork.com"
```

### Steps Performed by the Script

1. **Elevation Check**: The script checks if it's running with administrative privileges. If not, it will re-launch itself with the necessary elevation.

2. **Chocolatey Installation**: The script installs Chocolatey if it is not already installed.

3. **OpenSSL Installation**: OpenSSL is installed via Chocolatey.

4. **Root CA Creation**: 
   - Generates a private key and a self-signed Root CA certificate using the provided `RootDomain` and other details.

5. **Certificate Signing Request (CSR) Creation**:
   - Generates a private key and a CSR for the domain specified in `CertDomain`.

6. **Certificate Signing**:
   - Signs the CSR using the Root CA to create a certificate for `CertDomain`.

7. **PFX Conversion**:
   - Converts the Root CA certificate and the signed certificate to PFX format for installation.

8. **Certificate Installation**:
   - Installs the Root CA as a trusted certificate on the local machine.
   - Installs the signed certificate for use on the machine. 

9. **Cleanup**:
   - Deletes all generated files (keys, CSRs, certificates, etc.).
   - Uninstalls OpenSSL to leave the system clean.

### Important Notes

- **Execution Policy**: If your system's execution policy prevents scripts from running, you can bypass this by running PowerShell with the `-ExecutionPolicy Bypass` parameter or by temporarily changing the execution policy using `Set-ExecutionPolicy`.

### Troubleshooting

- **OpenSSL Not Found**: If the script cannot find OpenSSL, ensure it is installed in the default Chocolatey directory: `C:\Program Files\OpenSSL\bin\openssl.exe`.
- **Permissions**: Ensure you run the script with administrative privileges to avoid permission issues.

### License

This script is provided "as is" without any warranty. Use it at your own risk.


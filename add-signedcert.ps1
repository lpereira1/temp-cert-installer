param (
    [string]$RootDomain,        # The root domain, e.g., codecraftednetworks.com
    [string]$CertDomain,        # The certificate domain, e.g., *.users.codecraftednetworks.com
    [string]$Country = "US",    # Country for the CA and certificate
    [string]$State = "State",   # State for the CA and certificate
    [string]$Locality = "City", # Locality (City) for the CA and certificate
    [string]$Organization = "Organization",  # Organization for the CA and certificate
    [string]$OrgUnit = "OrgUnit",             # Organizational Unit for the CA and certificate
    [string]$Email = "admin@domain.com"       # Email for the CA and certificate
)

# Check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Relaunch the script as an administrator in the same window
if (-not (Test-Administrator)) {
    Write-Host "Elevating script to run as administrator in the same window..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs -Wait
    exit
}

# Install Chocolatey and OpenSSL
function Install-Chocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            Write-Host "Chocolatey installed successfully."
        } catch {
            Write-Error "Failed to install Chocolatey. Error: $_"
            exit 1
        }
    } else {
        Write-Host "Chocolatey is already installed."
    }
}

# Install OpenSSL
Install-Chocolatey
try {
    choco install openssl.light -y
    Write-Host "OpenSSL installed successfully."
} catch {
    Write-Error "Failed to install OpenSSL via Chocolatey. Error: $_"
    exit 1
}

# Set the full path to the OpenSSL executable
$opensslPath = "C:\Program Files\OpenSSL\bin\openssl.exe"

# Ensure OpenSSL is found
if (-not (Test-Path $opensslPath)) {
    Write-Error "OpenSSL not found at $opensslPath. Please check the installation."
    exit 1
}

# Set file names
$rootKey = "$RootDomain-RootCA.key"
$rootCert = "$RootDomain-RootCA.pem"
$rootCertPfx = "$RootDomain-RootCA.pfx"
$certKey = "$CertDomain.key"
$certCsr = "$CertDomain.csr"
$certCert = "$CertDomain.crt"
$certCertPfx = "$CertDomain.pfx"
$extFile = "$CertDomain.ext"

try {
    # Create Root CA
    & "$opensslPath" genrsa -out $rootKey 4096
    & "$opensslPath" req -x509 -new -nodes -key $rootKey -sha256 -days 3650 -out $rootCert -subj "/C=$Country/ST=$State/L=$Locality/O=$Organization/OU=$OrgUnit/CN=$RootDomain/emailAddress=$Email"
    Write-Host "Root CA created successfully."
} catch {
    Write-Error "Failed to create Root CA. Error: $_"
    exit 1
}

try {
    # Generate a private key and CSR for the certificate
    & "$opensslPath" genrsa -out $certKey 2048
    & "$opensslPath" req -new -key $certKey -out $certCsr -subj "/C=$Country/ST=$State/L=$Locality/O=$Organization/OU=$OrgUnit/CN=$CertDomain/emailAddress=$Email"
    Write-Host "Private key and CSR for certificate generated successfully."
} catch {
    Write-Error "Failed to generate private key or CSR. Error: $_"
    exit 1
}

try {
    # Create a configuration file for extensions
    @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CertDomain
"@ | Out-File -Encoding ASCII $extFile

    # Sign the certificate with the Root CA
    & "$opensslPath" x509 -req -in $certCsr -CA $rootCert -CAkey $rootKey -CAcreateserial -out $certCert -days 825 -sha256 -extfile $extFile
    Write-Host "Certificate signed successfully."
} catch {
    Write-Error "Failed to sign the certificate. Error: $_"
    exit 1
}

try {
    # Convert the Root CA and certificate to PFX format
    & "$opensslPath" pkcs12 -export -out $rootCertPfx -inkey $rootKey -in $rootCert -passout pass:
    & "$opensslPath" pkcs12 -export -out $certCertPfx -inkey $certKey -in $certCert -passout pass:
    Write-Host "Certificates converted to PFX format successfully."
} catch {
    Write-Error "Failed to convert certificates to PFX format. Error: $_"
    exit 1
}

try {
    # Install the Root CA as a trusted certificate
    Import-PfxCertificate -FilePath $rootCertPfx -CertStoreLocation Cert:\LocalMachine\Root
    Write-Host "Root CA installed as a trusted certificate successfully."
} catch {
    Write-Error "Failed to install Root CA as a trusted certificate. Error: $_"
    exit 1
}

try {
    # Install the certificate in IIS (assuming IIS is installed and configured)c
    Import-PfxCertificate -FilePath $certCertPfx -CertStoreLocation Cert:\LocalMachine\My 
    Write-Host "Certificate installed in IIS successfully."
} catch {
    Write-Error "Failed to install the certificate in IIS. Error: $_"
    exit 1
}

try {
    # Clean up files
    Remove-Item $rootKey, $rootCert, "$RootDomain-RootCA.srl", $rootCertPfx, $certKey, $certCsr, $certCert, $certCertPfx, $extFile -Force
    Write-Host "Temporary files cleaned up successfully."
} catch {
    Write-Error "Failed to clean up temporary files. Error: $_"
    exit 1
}

try {
    # Uninstall OpenSSL
    choco uninstall openssl.light -y
    Write-Host "OpenSSL uninstalled successfully."
} catch {
    Write-Error "Failed to uninstall OpenSSL. Error: $_"
    exit 1
}

Write-Host "Process complete. Root CA and certificate installed, and all files cleaned up."

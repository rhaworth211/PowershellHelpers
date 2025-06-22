# PowershellHelpers

**PowershellHelpers** is a collection of PowerShell utility functions and scripts designed to simplify common development, DevOps, and automation tasks. Built with reusability and clarity in mind, these helpers are intended to accelerate productivity for engineers working in Windows or cloud environments.

---

## ✨ Features

- 🔑 Azure authentication helpers (MSAL, Managed Identity)
- 📦 Script packaging and deployment tools
- 🧪 Pester testing support
- 🧹 Utility functions for file cleanup, logging, validation
- 📂 Directory and environment setup
- 🧭 REST API helpers for generic web calls

---

## 📁 Example Structure

```bash
├── src/
│   ├── Auth/
│   │   └── Get-MsalToken.ps1
│   ├── Azure/
│   │   └── Get-BlobSasToken.ps1
│   ├── General/
│   │   └── Write-Log.ps1
│   │   └── Remove-OldFiles.ps1
├── tests/
│   └── General.Tests.ps1
├── PowershellHelpers.psd1
├── PowershellHelpers.psm1
```

---

## 🚀 Usage

Import the module into your PowerShell session:

```powershell
Import-Module ./PowershellHelpers.psm1
```

Then call any function:

```powershell
Write-Log -Message "Script started"
$token = Get-MsalToken -ClientId $clientId -TenantId $tenantId -Resource $resource
```

---

## 🧪 Running Tests

This project supports [Pester](https://pester.dev/):

```powershell
Invoke-Pester ./tests
```

---

## 🌐 Example: Azure Token with Managed Identity

```powershell
function Get-ManagedIdentityToken {
    param (
        [string]$Resource = "https://management.azure.com/"
    )

    $uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$Resource"
    $headers = @{ Metadata = "true" }

    Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
}
```

---

## 🔄 Installation

You can clone or symlink the module, or install it from a private PSGallery:

```powershell
Install-Module -Name PowershellHelpers -Scope CurrentUser -Repository PSGallery
```

> Replace `PSGallery` with your own if publishing privately.

---

## 📄 License

MIT License — see `LICENSE` for details.

---

> Created by [Ryan Haworth](mailto:r.haworth@outlook.com)

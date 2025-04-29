# AzStorageAccountBlobHelper.psm1

$script:ManagedIdentityClientId = $null

function Test-AzCliInstalled {
    <#
    .SYNOPSIS
        Verifies that the Azure CLI is installed; installs it if not present.
    #>
    Write-Verbose "Checking for Azure CLI..."
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Verbose "Azure CLI not found; installing..."
        Install-AzCli
    }

    try {
        $versionJson = az version --output json 2>$null | ConvertFrom-Json
        $version = $versionJson.'azure-cli'  ?? $versionJson.azcliversion ?? 'Unknown'
        Write-Verbose "Azure CLI version: $version"
    }
    catch {
        throw "Unable to verify Azure CLI installation. $_"
    }
}

function Install-AzCli {
    <#
    .SYNOPSIS
        Installs the Azure CLI on Windows or Linux.
    #>
    Write-Verbose "Installing Azure CLI..."
    if ($IsWindows) {
        $msiUrl   = 'https://aka.ms/installazurecliwindows'
        $tempMsi  = Join-Path $env:TEMP 'AzureCLI.msi'
        Invoke-WebRequest -Uri $msiUrl -OutFile $tempMsi -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i `"$tempMsi`" /quiet /qn /norestart" -Wait
        Remove-Item $tempMsi -Force
    }
    else {
        bash -c "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    }
    Write-Verbose "Azure CLI installation complete."
}

function Connect-StorageAccountBlobHelperMsi {
    <#
    .SYNOPSIS
        Authenticates Azure CLI using a user-assigned managed identity.
    .PARAMETER ClientId
        The client ID of the user-assigned managed identity.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ClientId
    )
    Test-AzCliInstalled
    Write-Verbose "Logging in with managed identity $ClientId..."
    az login --identity -u $ClientId | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "az login failed."
    }
    $script:ManagedIdentityClientId = $ClientId
    Write-Verbose "Logged in with managed identity."
}

function Get-StorageContainer {
    <#
    .SYNOPSIS
        Lists all containers in a storage account.
    .PARAMETER StorageAccountName
        Name of the storage account.
    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorageAccountName
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    az storage container list `
        --account-name $StorageAccountName `
        --auth-mode login `
        --output json |
      ConvertFrom-Json
}

function New-StorageContainer {
    <#
    .SYNOPSIS
        Creates a new container.
    .PARAMETER StorageAccountName
    .PARAMETER ContainerName
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorageAccountName,
        [Parameter(Mandatory)][string]$ContainerName
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    $json = az storage container create `
        --account-name $StorageAccountName `
        --name $ContainerName `
        --auth-mode login `
        --output json
    ConvertFrom-Json $json
}

function Remove-StorageContainer {
    <#
    .SYNOPSIS
        Deletes a container.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorageAccountName,
        [Parameter(Mandatory)][string]$ContainerName
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    az storage container delete `
        --account-name $StorageAccountName `
        --name $ContainerName `
        --yes `
        --auth-mode login | Out-Null
    Write-Verbose "Container '$ContainerName' deleted."
}

function Get-StorageBlob {
    <#
    .SYNOPSIS
        Lists blobs in a container.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorageAccountName,
        [Parameter(Mandatory)][string]$ContainerName
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    az storage blob list `
        --account-name $StorageAccountName `
        --container-name $ContainerName `
        --auth-mode login `
        --output json |
      ConvertFrom-Json
}

function Add-StorageBlob {
    <#
    .SYNOPSIS
        Uploads a file as a blob.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorageAccountName,
        [Parameter(Mandatory)][string]$ContainerName,
        [Parameter(Mandatory)][string]$FilePath,
        [string]$BlobName = $(Split-Path -Leaf $FilePath)
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    $json = az storage blob upload `
        --account-name $StorageAccountName `
        --container-name $ContainerName `
        --name $BlobName `
        --file $FilePath `
        --auth-mode login `
        --output json
    ConvertFrom-Json $json
}

function Get-StorageBlobContent {
    <#
    .SYNOPSIS
        Downloads a blob to a local path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorageAccountName,
        [Parameter(Mandatory)][string]$ContainerName,
        [Parameter(Mandatory)][string]$BlobName,
        [Parameter(Mandatory)][string]$DestinationPath
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    $destDir = Split-Path $DestinationPath -Parent
    if ($destDir -and -not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory | Out-Null
    }
    az storage blob download `
        --account-name $StorageAccountName `
        --container-name $ContainerName `
        --name $BlobName `
        --file $DestinationPath `
        --auth-mode login | Out-Null
    Write-Verbose "Downloaded '$BlobName' to '$DestinationPath'."
}

function Remove-StorageBlob {
    <#
    .SYNOPSIS
        Deletes a blob.
    #>
    [CmdletBinding()]    
    param(
        [Parameter(Mandatory)][string]$StorageAccountName,
        [Parameter(Mandatory)][string]$ContainerName,
        [Parameter(Mandatory)][string]$BlobName
    )
    Test-AzCliInstalled
    if (-not $script:ManagedIdentityClientId) {
        throw 'Please run Connect-StorageAccountBlobHelperMsi -ClientId <ID> first.'
    }
    az storage blob delete `
        --account-name $StorageAccountName `
        --container-name $ContainerName `
        --name $BlobName `
        --auth-mode login | Out-Null
    Write-Verbose "Deleted blob '$BlobName'."
}

Export-ModuleMember `
  -Function Test-AzCliInstalled,Install-AzCli,Connect-StorageAccountBlobHelperMsi,`
                Get-StorageContainer,New-StorageContainer,Remove-StorageContainer,`
                Get-StorageBlob,Add-StorageBlob,Get-StorageBlobContent,Remove-StorageBlob
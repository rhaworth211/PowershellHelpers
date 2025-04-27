$script:AccessToken = $null
$script:AccessTokenExpiry = $null
$script:ClientId = $null
Import-Module "$PSScriptRoot\RestHelper.psm1" -Force

function Set-StorageManagedIdentity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ClientId
    )

    $script:ClientId = $ClientId
    Write-Verbose "Using Managed Identity ClientId: $ClientId"
}

function Get-AccessToken {
    $resource = "https://storage.azure.com/"

    if (-not $script:AccessToken -or (Get-Date) -ge $script:AccessTokenExpiry) {
        $metadataUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2019-08-01&resource=$resource"
        
        if ($script:ClientId) {
            $metadataUri += "&client_id=$($script:ClientId)"
        }

        $tokenResponse = Invoke-WithRetry -Uri $metadataUri `
            -Method GET `
            -Headers @{Metadata="true"} `
            -ErrorAction Stop

        $script:AccessToken = $tokenResponse.access_token
        $script:AccessTokenExpiry = (Get-Date).AddSeconds($tokenResponse.expires_in - 60) # Refresh 1 min early
    }

    return $script:AccessToken
}

function New-Blob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        [Parameter(Mandatory)]
        [string]$ContainerName,
        [Parameter(Mandatory)]
        [string]$BlobName,
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $token = Get-AccessToken
    $url = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName"
    $fileBytes = Get-Content -Path $FilePath -Encoding Byte -ReadCount 0

    Invoke-WithRetry -Uri $url -Method PUT -Headers @{
        Authorization = "Bearer $token"
        "x-ms-blob-type" = "BlockBlob"
        "x-ms-version" = "2021-10-04"
    } -Body $fileBytes
}

function Get-Blob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        [Parameter(Mandatory)]
        [string]$ContainerName,
        [Parameter(Mandatory)]
        [string]$BlobName,
        [Parameter(Mandatory)]
        [string]$DownloadPath
    )

    $token = Get-AccessToken
    $url = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName"

    Invoke-WithRetry -Uri $url `
        -Method GET `
        -Headers @{
            Authorization = "Bearer $token"
            "x-ms-version" = "2021-10-04"
        } `
        -OutFile $DownloadPath `
        -ErrorAction Stop
}

function Remove-Blob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        [Parameter(Mandatory)]
        [string]$ContainerName,
        [Parameter(Mandatory)]
        [string]$BlobName
    )

    $token = Get-AccessToken
    $url = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName"

    Invoke-WithRetry -Uri $url `
        -Method DELETE `
        -Headers @{
            Authorization = "Bearer $token"
            "x-ms-version" = "2021-10-04"
        } `
        -ErrorAction Stop
}

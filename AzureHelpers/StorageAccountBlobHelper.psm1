$script:AccessToken = $null
$script:AccessTokenExpiry = $null
$script:ClientId = $null

function Invoke-WithRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'PUT', 'POST', 'DELETE')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $false)]
        $Body,

        [Parameter(Mandatory = $false)]
        [string]$OutFile
    )

    $maxRetries = 5
    $retryDelaySeconds = 2

    for ($i = 0; $i -lt $maxRetries; $i++) {
        try {
            if ($OutFile) {
                return Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -OutFile $OutFile -Body $Body -ErrorAction Stop
            }
            else {
                return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body $Body -ErrorAction Stop
            }
        }
        catch {
            if ($_.Exception.Response.StatusCode.Value__ -in 429, 500, 502, 503, 504) {
                Write-Host "Request failed with status $($_.Exception.Response.StatusCode.Value__). Retrying in $retryDelaySeconds seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryDelaySeconds
                $retryDelaySeconds *= 2
            }
            else {
                throw
            }
        }
    }

    throw "Request failed after $maxRetries attempts."
}

function Set-StorageManagedIdentity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ClientId
    )

    $script:ClientId = $ClientId
    Write-Verbose "Using Managed Identity ClientId: $ClientId"
}

function Get-ClientId {
    return $script:ClientId
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

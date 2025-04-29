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
        [string]$OutFile,

        [Parameter()]
        [int]$MaxRetries = 5,

        [Parameter()]
        [int]$RetryDelaySeconds = 2
    )

    if ($OutFile -and $Body) {
        throw "Cannot specify both OutFile and Body."
    }

    $currentRetryDelay = $RetryDelaySeconds

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            if ($OutFile) {
                return Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -OutFile $OutFile
            }
            else {
                return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body $Body
            }
        }
        catch {
            if ($_.Exception.Response.StatusCode.Value__ -in 429, 500, 502, 503, 504) {
                Write-Host "Request failed with status $($_.Exception.Response.StatusCode.Value__). Retrying in $currentRetryDelay seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $currentRetryDelay
                $currentRetryDelay *= 2
            }
            else {
                throw
            }
        }
        finally {
            $ErrorActionPreference = $oldErrorActionPreference
        }
    }

    throw "Request failed after $MaxRetries attempts."
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

function Set-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$AccessToken,
        [Parameter(Mandatory = $false)]
        [string]$AccessTokenExpiry
    )

    $script:AccessToken = $AccessToken
    $script:AccessTokenExpiry = $AccessTokenExpiry
    Write-Verbose "Using AccessToken: $script:AccessToken"
    Write-Verbose "Using AccessTokenExpiry: $script:AccessTokenExpiry"
}

function Get-AccessToken {
    $resource = "https://storage.azure.com/"

    if (-not $script:AccessToken -or (Get-Date) -ge $script:AccessTokenExpiry) {
        $queryParams = "api-version=2019-08-01&resource=$resource"
        if ($script:ClientId) {
            $queryParams += "&client_id=$($script:ClientId)"
        }

        $metadataUri = "http://169.254.169.254/metadata/identity/oauth2/token?$queryParams"

        $tokenResponse = Invoke-WithRetry -Uri $metadataUri `
            -Method GET `
            -Headers @{Metadata="true"}

        $script:AccessToken = $tokenResponse.access_token
        $script:AccessTokenExpiry = (Get-Date).AddSeconds($tokenResponse.expires_in - 60)
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
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("BlockBlob", "AppendBlob", "PageBlob")]
        [string]$BlobType = "BlockBlob"
    )

    $token = Get-AccessToken
    $url = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName"
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

    return Invoke-WithRetry -Uri $url -Method PUT -Headers @{
        Authorization = "Bearer $token"
        "x-ms-blob-type" = $BlobType
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

    return Invoke-WithRetry -Uri $url `
        -Method GET `
        -Headers @{
            Authorization = "Bearer $token"
            "x-ms-version" = "2021-10-04"
        } `
        -OutFile $DownloadPath
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

    return Invoke-WithRetry -Uri $url `
        -Method DELETE `
        -Headers @{
            Authorization = "Bearer $token"
            "x-ms-version" = "2021-10-04"
        }
}

Export-ModuleMember -Function Set-StorageManagedIdentity, Get-ClientId, Set-AccessToken, Get-AccessToken, New-Blob, Get-Blob, Remove-Blob
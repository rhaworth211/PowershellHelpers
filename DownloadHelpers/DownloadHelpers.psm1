function Get-DownloadFromUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter()]
        [string]$DestinationPath = (Join-Path -Path $env:TEMP -ChildPath (Split-Path -Path $Url -Leaf)),
        [Parameter()]
        [switch]$Overwrite,
        [Parameter()]
        [hashtable]$Headers,
        [Parameter()]
        [int]$TimeoutSec,
        [Parameter()]
        [string]$Method = 'GET',
        [Parameter()]
        [object]$Body,
        [Parameter()]
        [string]$UserAgent,
        [Parameter()]
        [string]$Proxy
    )

    if (Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue) {
        if ($Overwrite) {
            Remove-Item -Path $DestinationPath -Force
        } else {
            Write-Host "File already exists at $DestinationPath. Use -Overwrite to replace it."
            return $DestinationPath
        }
    }

    try {
        $params = @{ Uri = $Url; OutFile = $DestinationPath; Method = $Method }
        if ($Headers) { $params['Headers'] = $Headers }
        if ($TimeoutSec) { $params['TimeoutSec'] = $TimeoutSec }
        if ($Body) { $params['Body'] = $Body }
        if ($UserAgent) { $params['UserAgent'] = $UserAgent }
        if ($Proxy) { $params['Proxy'] = $Proxy }

        Invoke-WebRequest @params -ErrorAction Stop
        Write-Host "Downloaded file to $DestinationPath"
        return $DestinationPath
    } catch {
        Write-Error "Failed to download file from $Url. Error: $_"
        return $null
    }
}

function Get-DownloadAndExtractFromUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter()]
        [string]$DestinationPath = (Join-Path -Path $env:TEMP -ChildPath (Split-Path -Path $Url -Leaf)),
        [Parameter()]
        [switch]$Overwrite,
        [Parameter()]
        [hashtable]$Headers,
        [Parameter()]
        [int]$TimeoutSec,
        [Parameter()]
        [string]$Method = 'GET',
        [Parameter()]
        [object]$Body,
        [Parameter()]
        [string]$UserAgent,
        [Parameter()]
        [string]$Proxy
    )

    $downloadedFile = Get-DownloadFromUrl -Url $Url -DestinationPath $DestinationPath -Overwrite:$Overwrite -Headers $Headers -TimeoutSec $TimeoutSec -Method $Method -Body $Body -UserAgent $UserAgent -Proxy $Proxy
    if (-not $downloadedFile) {
        Write-Error "Download failed. Extraction skipped."
        return
    }

    try {
        if ($downloadedFile -like '*.zip') {
            Expand-Archive -Path $downloadedFile -DestinationPath (Split-Path -Parent $downloadedFile) -Force
            Write-Host "Extracted archive to $(Split-Path -Parent $downloadedFile)"
        } else {
            Write-Warning "Downloaded file is not a ZIP archive. Skipping extraction."
        }
    } catch {
        Write-Error "Failed to extract archive: $_"
    }
}

Export-ModuleMember -Function Get-DownloadFromUrl, Get-DownloadAndExtractFromUrl
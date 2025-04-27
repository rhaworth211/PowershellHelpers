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

Export-ModuleMember -Function Invoke-WithRetry
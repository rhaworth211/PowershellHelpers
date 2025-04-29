Import-Module "$PSScriptRoot/../DownloadHelpers.psm1" -Force

Describe 'Get-DownloadFromUrl' {
    It 'Should download a file successfully' {
        Mock -CommandName Invoke-WebRequest -MockWith { @{ StatusCode = 200 } }
        $result = Get-DownloadFromUrl -Url 'https://example.com/file.txt' -DestinationPath "$env:TEMP\file.txt" -Overwrite
        $result | Should -Be "$env:TEMP\file.txt"
    }
}

Describe 'Get-DownloadAndExtractFromUrl' {
    It 'Should download and extract a zip file successfully' {
        Mock -CommandName Invoke-WebRequest -MockWith { @{ StatusCode = 200 } }
        Mock -CommandName Expand-Archive -MockWith { }
        $result = Get-DownloadAndExtractFromUrl -Url 'https://example.com/archive.zip' -DestinationPath "$env:TEMP\archive.zip" -Overwrite
        $result | Should -BeNullOrEmpty
    }
}

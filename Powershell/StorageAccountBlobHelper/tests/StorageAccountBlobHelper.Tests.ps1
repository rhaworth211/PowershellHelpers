BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot "..\StorageAccountBlobHelper.psm1"

    if (-not (Test-Path $ModulePath)) {
        throw "Module not found at path: $ModulePath"
    }

    Import-Module $ModulePath -Force
}

Describe "StorageAccountBlobHelper Module Tests" {

    Context "Set-StorageManagedIdentity Tests" {
        It "Should set the ClientId variable" {
            Set-StorageManagedIdentity -ClientId "fake-client-id"
            (Get-ClientId) | Should -Be "fake-client-id"
        }

        It "Should clear the ClientId when no parameter is passed" {
            Set-StorageManagedIdentity
            (Get-ClientId) | Should -BeNullOrEmpty
        }
    }
}

Describe "Get-AccessToken Tests - When token is expired" {
    BeforeAll {        
        Mock -CommandName Invoke-WithRetry -ModuleName StorageAccountBlobHelper { @{ access_token = "mock-token"; expires_in = 3600 } }
    }

    It "Should retrieve and cache an access token when expired" {

        Set-AccessToken -AccessToken $null -AccessTokenExpiry (Get-Date).AddMinutes(-5)       

        $token = Get-AccessToken
        $token | Should -Be "mock-token"
    }
}

Describe "Get-AccessToken Tests - When token is valid and cached" {
    BeforeAll {        
        Mock -CommandName Invoke-WithRetry -ModuleName StorageAccountBlobHelper { throw "Invoke-WithRetry should not be called for cached tokens!" }
    }

    It "Should use cached token if not expired" {
        Set-AccessToken -AccessToken 'cached-token' -AccessTokenExpiry (Get-Date).AddMinutes(30)         

        $token = Get-AccessToken
        $token | Should -Be "cached-token"
    }
}

Describe "New-Blob Tests" {
    BeforeAll {
        Mock Get-AccessToken { "mock-token" }
        Mock -CommandName Invoke-WithRetry -ModuleName StorageAccountBlobHelper { @{ StatusCode = 201 } }
    }

    It "Should upload blob successfully" {
        $filePath = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($filePath, "Mock file content")

        try {
            $result = New-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "testblob.txt" -FilePath $filePath

            $result.StatusCode | Should -Be 201 
        }
        finally {
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "Get-Blob Tests" {    
    BeforeAll {
        Mock -CommandName Get-AccessToken { "mock-token" }
        Mock -CommandName Invoke-WithRetry -ModuleName StorageAccountBlobHelper { @{ StatusCode = 201 } }
    }

    It "Should call Invoke-WithRetry when downloading blob" {
        $downloadPath = "$env:TEMP\downloadedfile.txt"

        $result = Get-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -DownloadPath $downloadPath
        
        $result.StatusCode | Should -Be 201
        
    }    
}

Describe "Remove-Blob Tests" {    
    BeforeAll {
        Mock -CommandName Get-AccessToken { "mock-token" }
        Mock -CommandName Invoke-WithRetry -ModuleName StorageAccountBlobHelper { @{ StatusCode = 201 } }
    }

    It "Should call Invoke-WithRetry to delete blob" {
        $result = Remove-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt"
        $result.StatusCode | Should -Be 201            
    }    
}
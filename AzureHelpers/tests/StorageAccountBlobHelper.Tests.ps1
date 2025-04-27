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

    Context "Get-AccessToken Tests" {
        BeforeAll {            
            Mock -CommandName Invoke-WithRetry -ModuleName StorageAccountBlobHelper { @{ access_token = "mock-token"; expires_in = 3600 } }
        }
        
        It "Should retrieve and cache an access token" {
            $ExecutionContext.SessionState.PSVariable.Set('script:AccessToken', $null)
            $ExecutionContext.SessionState.PSVariable.Set('script:AccessTokenExpiry', (Get-Date).AddMinutes(-5))
    
            $token = Get-AccessToken
            $token | Should -Be "mock-token"
        }
    
        It "Should use cached token if not expired" {
            $ExecutionContext.SessionState.PSVariable.Set('script:AccessToken', 'cached-token')
            $ExecutionContext.SessionState.PSVariable.Set('script:AccessTokenExpiry', (Get-Date).AddMinutes(30))
    
            $token = Get-AccessToken
            $token | Should -Be "cached-token"
        }
    }    

    Context "New-Blob Tests" {
        BeforeEach {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-WithRetry { }
        }

        It "Should call Invoke-WithRetry with correct parameters when creating blob" {
            $filePath = "$env:TEMP\mockfile.txt"
            Set-Content -Path $filePath -Value "Test content"

            New-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -FilePath $filePath

            Assert-MockCalled Invoke-WithRetry -Times 1 -Exactly
            Remove-Item $filePath
        }
    }

    Context "Get-Blob Tests" {
        BeforeEach {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-WithRetry { }
        }

        It "Should call Invoke-WithRetry when downloading blob" {
            $downloadPath = "$env:TEMP\downloadedfile.txt"

            Get-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -DownloadPath $downloadPath

            Assert-MockCalled Invoke-WithRetry -Times 1 -Exactly
        }
    }

    Context "Remove-Blob Tests" {
        BeforeEach {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-WithRetry { }
        }

        It "Should call Invoke-WithRetry to delete blob" {
            Remove-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt"

            Assert-MockCalled Invoke-WithRetry -Times 1 -Exactly
        }
    }
}

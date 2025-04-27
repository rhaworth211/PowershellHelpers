BeforeAll {
    
    Import-Module "$PSScriptRoot\..\StorageAccountBlobHelper.psm1" -Force
}

Describe "StorageAccountBlobHelper Module Tests" {

    Context "Set-StorageManagedIdentity Tests" {
        It "Should set the ClientId variable" {
            Set-StorageManagedIdentity -ClientId "fake-client-id"
            $ExecutionContext.SessionState.PSVariable.GetValue('script:ClientId') | Should -Be "fake-client-id"
        }

        It "Should clear the ClientId when no parameter is passed" {
            Set-StorageManagedIdentity
            $ExecutionContext.SessionState.PSVariable.GetValue('script:ClientId') | Should -BeNullOrEmpty
        }
    }

    Context "Get-AccessToken Tests" {
        BeforeEach {
            Mock Invoke-RestMethod { @{ access_token = "mock-token"; expires_in = 3600 } }
        }

        It "Should retrieve and cache an access token" {
            $ExecutionContext.SessionState.PSVariable.Set('script:AccessToken', $null)
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
            Mock Invoke-RestMethod { }
        }

        It "Should call Invoke-RestMethod with correct parameters when creating blob" {
            $filePath = "$env:TEMP\mockfile.txt"
            Set-Content -Path $filePath -Value "Test content"

            New-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -FilePath $filePath

            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
            Remove-Item $filePath
        }
    }

    Context "Get-Blob Tests" {
        BeforeEach {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-WebRequest { }
        }

        It "Should call Invoke-WebRequest when downloading blob" {
            $downloadPath = "$env:TEMP\downloadedfile.txt"

            Get-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -DownloadPath $downloadPath

            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly
        }
    }

    Context "Update-Blob Tests" {
        BeforeEach {
            Mock New-Blob { }
        }

        It "Should internally call New-Blob for updating blob" {
            $filePath = "$env:TEMP\mockfile.txt"
            Set-Content -Path $filePath -Value "Updated content"

            Update-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -FilePath $filePath

            Assert-MockCalled New-Blob -Times 1 -Exactly
            Remove-Item $filePath
        }
    }

    Context "Remove-Blob Tests" {
        BeforeEach {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-RestMethod { }
        }

        It "Should call Invoke-RestMethod to delete blob" {
            Remove-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt"

            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }
}

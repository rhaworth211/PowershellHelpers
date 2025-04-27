Import-Module "$PSScriptRoot\..\StorageAccountBlobHelper.psm1" -Force


BeforeAll {
    Mock Invoke-RestMethod { @{ access_token = "mock-token"; expires_in = 3600 } }
    Mock Invoke-WebRequest { }
}

Describe "StorageAccountBlobHelper Module Tests" {

    Context "Set-StorageManagedIdentity Tests" {
        It "Should set the ClientId variable" {
            Set-StorageManagedIdentity -ClientId "fake-client-id"
            $script:ClientId | Should -Be "fake-client-id"
        }

        It "Should clear the ClientId when no parameter is passed" {
            Set-StorageManagedIdentity
            $script:ClientId | Should -BeNullOrEmpty
        }
    }

    Context "Get-AccessToken Tests" {
        It "Should retrieve and cache an access token" {
            $script:AccessToken = $null
            $token = Get-AccessToken
            $token | Should -Be "mock-token"
            $script:AccessToken | Should -Be "mock-token"
        }

        It "Should use cached token if not expired" {
            $script:AccessToken = "cached-token"
            $script:AccessTokenExpiry = (Get-Date).AddMinutes(30)
            $token = Get-AccessToken
            $token | Should -Be "cached-token"
        }
    }

    Context "New-Blob Tests" {
        It "Should call Invoke-RestMethod with correct parameters when creating blob" {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-RestMethod { }

            $filePath = "$env:TEMP\mockfile.txt"
            Set-Content -Path $filePath -Value "Test content"

            New-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -FilePath $filePath

            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
            Remove-Item $filePath
        }
    }

    Context "Get-Blob Tests" {
        It "Should call Invoke-WebRequest when downloading blob" {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-WebRequest { }

            $downloadPath = "$env:TEMP\downloadedfile.txt"

            Get-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -DownloadPath $downloadPath

            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly
        }
    }

    Context "Update-Blob Tests" {
        It "Should internally call New-Blob for updating blob" {
            Mock New-Blob { }

            $filePath = "$env:TEMP\mockfile.txt"
            Set-Content -Path $filePath -Value "Updated content"

            Update-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -FilePath $filePath

            Assert-MockCalled New-Blob -Times 1 -Exactly
            Remove-Item $filePath
        }
    }

    Context "Remove-Blob Tests" {
        It "Should call Invoke-RestMethod to delete blob" {
            Mock Get-AccessToken { "mock-token" }
            Mock Invoke-RestMethod { }

            Remove-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt"

            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }
}

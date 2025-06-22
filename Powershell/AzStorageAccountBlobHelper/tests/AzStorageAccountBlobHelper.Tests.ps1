BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot "..\AzStorageAccountBlobHelper.psm1"

    if (-not (Test-Path $ModulePath)) {
        throw "Module not found at path: $ModulePath"
    }

    Import-Module $ModulePath -Force
}

Describe 'AzStorageAccountBlobHelper Module Tests' {

    Context 'Test-AzCliInstalled' {
        It 'Should call Install-AzCli if az is missing' {
            Mock Get-Command { $null }
            Mock Install-AzCli {}

            Test-AzCliInstalled

            Should -Invoke Install-AzCli -Exactly 1
        }

        It 'Should not call Install-AzCli if az is present' {
            Mock Get-Command { @{ Name = 'az' } }
            Mock Install-AzCli {}

            Test-AzCliInstalled

            Should -Not -Invoke Install-AzCli
        }
    }

    Context 'Connect-StorageAccountBlobHelperMsi' {
        It 'Should login using the provided ClientId' {
            Mock Test-AzCliInstalled {}
            Mock az { '{"tenantId":"fake"}' }

            Connect-StorageAccountBlobHelperMsi -ClientId 'test-client-id'

            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match '--identity' -and $args -match 'test-client-id' }
            $script:ManagedIdentityClientId | Should -Be 'test-client-id'
        }
    }

    Context 'Get-StorageContainer' {
        It 'Should throw if not connected' {
            $script:ManagedIdentityClientId = $null
            { Get-StorageContainer -StorageAccountName 'teststorage' } | Should -Throw
        }

        It 'Should call az storage container list' {
            $script:ManagedIdentityClientId = 'mock-client-id'
            Mock Test-AzCliInstalled {}
            Mock az { '[]' }

            Get-StorageContainer -StorageAccountName 'teststorage'

            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage container list' }
        }
    }

    Context 'New-StorageContainer' {
        It 'Should call az storage container create' {
            $script:ManagedIdentityClientId = 'mock-client-id'
            Mock Test-AzCliInstalled {}
            Mock az { '{}' }

            New-StorageContainer -StorageAccountName 'teststorage' -ContainerName 'newcontainer'

            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage container create' }
        }
    }

    Context 'Remove-StorageContainer' {
        It 'Should call az storage container delete' {
            $script:ManagedIdentityClientId = 'mock-client-id'
            Mock Test-AzCliInstalled {}
            Mock az {}

            Remove-StorageContainer -StorageAccountName 'teststorage' -ContainerName 'oldcontainer'

            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage container delete' }
        }
    }

    Context 'Blob Operations' {
        BeforeEach {
            $script:ManagedIdentityClientId = 'mock-client-id'
            Mock Test-AzCliInstalled {}
            Mock az { '{}' }
        }

        It 'Get-StorageBlob should call az storage blob list' {
            Get-StorageBlob -StorageAccountName 'teststorage' -ContainerName 'testcontainer'
            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage blob list' }
        }

        It 'Add-StorageBlob should call az storage blob upload' {
            Mock Test-Path { $true }

            Add-StorageBlob -StorageAccountName 'teststorage' -ContainerName 'testcontainer' -FilePath 'fakepath.txt'

            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage blob upload' }
        }

        It 'Add-StorageBlob should throw if file missing' {
            Mock Test-Path { $false }

            { Add-StorageBlob -StorageAccountName 'teststorage' -ContainerName 'testcontainer' -FilePath 'missingfile.txt' } | Should -Throw
        }

        It 'Get-StorageBlobContent should call az storage blob download' {
            Mock Test-Path { $true }

            Get-StorageBlobContent -StorageAccountName 'teststorage' -ContainerName 'testcontainer' -BlobName 'blob.txt' -DestinationPath 'c:\temp\blob.txt'

            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage blob download' }
        }

        It 'Remove-StorageBlob should call az storage blob delete' {
            Remove-StorageBlob -StorageAccountName 'teststorage' -ContainerName 'testcontainer' -BlobName 'oldblob.txt'
            Should -Invoke az -Exactly 1 -ParameterFilter { $args -match 'storage blob delete' }
        }
    }
}

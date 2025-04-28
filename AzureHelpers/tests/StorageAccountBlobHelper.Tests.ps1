BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot "..\StorageAccountBlobHelper.psm1"

    if (-not (Test-Path $ModulePath)) {
        throw "Module not found at path: $ModulePath"
    }

    Import-Module $ModulePath -Force
}

Describe "StorageAccountBlobHelper Module Tests" {

    Context "Set-StorageManagedIdentity Tests" {
        InModuleScope StorageAccountBlobHelper {
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

    Context "Get-AccessToken Tests" {
        Describe "When token is expired" {
            InModuleScope StorageAccountBlobHelper {
                BeforeAll {
                    Mock Invoke-WithRetry { @{ access_token = "mock-token"; expires_in = 3600 } }
                }

                It "Should retrieve and cache an access token when expired" {
                    Set-AccessToken -AccessToken $null -AccessTokenExpiry (Get-Date).AddMinutes(-5)

                    $token = Get-AccessToken
                    $token | Should -Be "mock-token"
                }
            }
        }

        Describe "When token is valid and cached" {
            InModuleScope StorageAccountBlobHelper {
                BeforeAll {
                    Mock Invoke-WithRetry { throw "Invoke-WithRetry should not be called for cached tokens!" }
                }

                It "Should use cached token if not expired" {
                    Set-AccessToken -AccessToken 'cached-token' -AccessTokenExpiry (Get-Date).AddMinutes(30)

                    $token = Get-AccessToken
                    $token | Should -Be "cached-token"
                }
            }
        }
    }

    Context "Blob Operations" {
        Describe "New-Blob Tests" {
            InModuleScope StorageAccountBlobHelper {
                BeforeAll {
                    Mock Get-AccessToken { "mock-token" }
                    Mock Invoke-WithRetry { @{ StatusCode = 201 } }
                }

                It "Should upload blob successfully" {
                    $filePath = [System.IO.Path]::GetTempFileName()
                    [System.IO.File]::WriteAllText($filePath, "Mock file content")

                    try {
                        $result = New-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "testblob.txt" -FilePath $filePath
                        
                        Assert-MockCalled Invoke-WithRetry -Times 1 -Exactly -ParameterFilter {
                            $Method -eq "PUT" -and $Uri -match "mockstorage.blob.core.windows.net"
                        }
                    }
                    finally {
                        Remove-Item $filePath -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        Describe "Get-Blob Tests" {
            InModuleScope StorageAccountBlobHelper {
                BeforeAll {
                    Mock Get-AccessToken { "mock-token" }
                    Mock Invoke-WithRetry { }
                }

                It "Should download blob successfully" {
                    $downloadPath = [System.IO.Path]::GetTempFileName()

                    try {
                        Get-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt" -DownloadPath $downloadPath

                        Assert-MockCalled Invoke-WithRetry -Times 1 -Exactly -ParameterFilter {
                            $Method -eq "GET" -and $Uri -match "mockstorage.blob.core.windows.net"
                        }
                    }
                    finally {
                        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        Describe "Remove-Blob Tests" {
            InModuleScope StorageAccountBlobHelper {
                BeforeAll {
                    Mock Get-AccessToken { "mock-token" }
                    Mock Invoke-WithRetry { }
                }

                It "Should delete blob successfully" {
                    Remove-Blob -StorageAccountName "mockstorage" -ContainerName "mockcontainer" -BlobName "mockblob.txt"

                    Assert-MockCalled Invoke-WithRetry -Times 1 -Exactly -ParameterFilter {
                        $Method -eq "DELETE" -and $Uri -match "mockstorage.blob.core.windows.net"
                    }
                }
            }
        }
    }
}

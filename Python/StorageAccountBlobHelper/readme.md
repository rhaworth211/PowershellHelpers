# StorageAccountBlobHelper

A lightweight Python module to simplify working with Azure Blob Storage using User Assigned Managed Identity or Default Azure Credentials.

## Features

- Upload blobs
- Download blobs
- Delete blobs
- List blobs
- Support for User-Assigned Managed Identity (Client ID)
- Support for DefaultAzureCredential fallback

## Installation

```bash
pip install storageaccountblobhelper
```

(Or clone/download and run:)
```bash
pip install .
```

## Usage

```python
from storageaccountblobhelper import StorageAccountBlobHelper

# Initialize with account name (and optional client_id for User Assigned Identity)
blob_helper = StorageAccountBlobHelper(account_name="mystorageaccount", client_id="your-client-id-optional")

# Upload a blob
blob_helper.upload_blob(container_name="mycontainer", blob_name="myfile.txt", file_path="./myfile.txt")

# Download a blob
blob_helper.download_blob(container_name="mycontainer", blob_name="myfile.txt", file_path="./downloaded.txt")

# List blobs
blobs = blob_helper.list_blobs(container_name="mycontainer")
print(blobs)

# Delete a blob
blob_helper.delete_blob(container_name="mycontainer", blob_name="myfile.txt")
```

## Requirements

- Python 3.7+
- azure-identity
- azure-storage-blob

Install dependencies:

```bash
pip install azure-identity azure-storage-blob
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

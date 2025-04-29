import os
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient

class StorageAccountBlobHelper:
    def __init__(self, account_name, client_id=None):
        self.account_name = account_name
        self.client_id = client_id
        self.credential = self.get_credential()

    def get_credential(self):
        if self.client_id:
            return ManagedIdentityCredential(client_id=self.client_id)
        else:
            return DefaultAzureCredential()

    def get_blob_service_client(self):
        url = f"https://{self.account_name}.blob.core.windows.net"
        return BlobServiceClient(account_url=url, credential=self.credential)

    def upload_blob(self, container_name, blob_name, file_path):
        service_client = self.get_blob_service_client()
        blob_client = service_client.get_blob_client(container=container_name, blob=blob_name)

        with open(file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)

    def download_blob(self, container_name, blob_name, file_path):
        service_client = self.get_blob_service_client()
        blob_client = service_client.get_blob_client(container=container_name, blob=blob_name)

        with open(file_path, "wb") as f:
            download_stream = blob_client.download_blob()
            f.write(download_stream.readall())

    def delete_blob(self, container_name, blob_name):
        service_client = self.get_blob_service_client()
        blob_client = service_client.get_blob_client(container=container_name, blob=blob_name)
        blob_client.delete_blob()

    def list_blobs(self, container_name):
        service_client = self.get_blob_service_client()
        container_client = service_client.get_container_client(container_name)

        blobs = container_client.list_blobs()
        return [blob.name for blob in blobs]
import unittest
from unittest.mock import patch, MagicMock
from StorageAccountBlobHelper import StorageAccountBlobHelper

class TestStorageAccountBlobHelper(unittest.TestCase):

    @patch('StorageAccountBlobHelper.BlobServiceClient')
    @patch('StorageAccountBlobHelper.DefaultAzureCredential')
    def setUp(self, mock_default_credential, mock_blob_service_client):
        self.helper = StorageAccountBlobHelper("testaccount")
        self.mock_blob_service_client = mock_blob_service_client

    @patch('StorageAccountBlobHelper.BlobServiceClient')
    def test_upload_blob(self, mock_blob_service_client):
        mock_blob_client = MagicMock()
        mock_blob_service_client.return_value.get_blob_client.return_value = mock_blob_client

        with patch("builtins.open", unittest.mock.mock_open(read_data=b"data")) as mock_file:
            self.helper.upload_blob("testcontainer", "testblob", "dummyfile.txt")

        mock_blob_client.upload_blob.assert_called_once()
        mock_file.assert_called_with("dummyfile.txt", "rb")

    @patch('StorageAccountBlobHelper.BlobServiceClient')
    def test_download_blob(self, mock_blob_service_client):
        mock_blob_client = MagicMock()
        mock_blob_client.download_blob.return_value.readall.return_value = b"data"
        mock_blob_service_client.return_value.get_blob_client.return_value = mock_blob_client

        with patch("builtins.open", unittest.mock.mock_open()) as mock_file:
            self.helper.download_blob("testcontainer", "testblob", "dummyfile.txt")

        mock_blob_client.download_blob.assert_called_once()
        mock_file.assert_called_with("dummyfile.txt", "wb")

    @patch('StorageAccountBlobHelper.BlobServiceClient')
    def test_delete_blob(self, mock_blob_service_client):
        mock_blob_client = MagicMock()
        mock_blob_service_client.return_value.get_blob_client.return_value = mock_blob_client

        self.helper.delete_blob("testcontainer", "testblob")
        mock_blob_client.delete_blob.assert_called_once()

    @patch('StorageAccountBlobHelper.BlobServiceClient')
    def test_list_blobs(self, mock_blob_service_client):
        mock_container_client = MagicMock()
        mock_container_client.list_blobs.return_value = [MagicMock(name="blob1"), MagicMock(name="blob2")]
        mock_blob_service_client.return_value.get_container_client.return_value = mock_container_client

        blobs = self.helper.list_blobs("testcontainer")
        self.assertEqual(blobs, ["blob1", "blob2"])

if __name__ == '__main__':
    unittest.main()

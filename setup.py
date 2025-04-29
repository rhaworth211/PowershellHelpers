
from setuptools import setup, find_packages

setup(
    name="storageaccountblobhelper",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "azure-identity",
        "azure-storage-blob",
    ],
    author="Your Name",
    author_email="your.email@example.com",
    description="A helper module for Azure Storage Blob operations using Managed Identity",
    long_description=open("README.md").read() if os.path.exists("README.md") else "",
    long_description_content_type="text/markdown",
    url="https://your-repository-url",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.7',
)

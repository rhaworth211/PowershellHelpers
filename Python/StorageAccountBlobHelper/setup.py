import os
from setuptools import setup, find_packages

this_directory = os.path.abspath(os.path.dirname(__file__))
readme_path = os.path.join(this_directory, "README.md")

try:
    with open(readme_path, encoding="utf-8") as f:
        long_description = f.read()
except FileNotFoundError:
    long_description = "A simple helper for Azure Blob Storage operations."

setup(
    name="StorageAccountBlobHelper",
    version="0.1.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="A simple helper for Azure Blob Storage operations using Managed Identity or Default Azure Credential.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/rhaworth211/StorageAccountBlobHelper",
    packages=find_packages(),
    install_requires=[
        "azure-identity>=1.7.0",
        "azure-storage-blob>=12.8.0",
    ],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Libraries",
    ],
    python_requires='>=3.7',
)

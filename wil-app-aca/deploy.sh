#!/bin/bash

# Load environment variables from .env file
source .env

# create a ressource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --query "properties.provisioningState"

# create a container app
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --query "properties.provisioningState"

export ENVIRONMENT_ID=$(az containerapp env show \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "id" \
  --output tsv)

echo $ENVIRONMENT_ID

# create storage account
RAND=$(head /dev/urandom | tr -dc a-z0-9 | head -c10 ; echo '')
STORAGE_ACCOUNT_NAME="woodilike$RAND"

echo "Storage account name is" $STORAGE_ACCOUNT_NAME

az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-large-file-share \
  --query "provisioningState"

# define a file share
FILE_SHARE_NAME="woodilikefileshare"

# create a file share
az storage share create \
  --name $FILE_SHARE_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query "provisioningState"

# Get the storage account key
export STORAGE_ACCOUNT_KEY=$(az storage account keys list \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].value" \
  --output tsv)

echo $STORAGE_ACCOUNT_KEY

# Define the storage mount name
export STORAGE_MOUNT_NAME="woodilikestoragemount"

# Create the storage mount
az containerapp env storage set \
  --access-mode ReadWrite \
  --azure-file-account-name $STORAGE_ACCOUNT_NAME \
  --azure-file-account-key $STORAGE_ACCOUNT_KEY \
  --azure-file-share-name $FILE_SHARE_NAME \
  --storage-name $STORAGE_MOUNT_NAME \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --output table




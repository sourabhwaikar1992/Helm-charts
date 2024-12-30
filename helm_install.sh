#!/bin/bash

# Check Helm installation
echo "Checking Helm installation..."
if ! command -v helm &> /dev/null
then
    echo "Helm is not installed. Installing Helm now..."
    
    # Download the Helm installation script
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    
    # Make the script executable
    chmod +x get_helm.sh
    
    # Execute the installation script
    ./get_helm.sh
    
    # Check if the installation was successful
    if command -v helm &> /dev/null; then
        echo "Helm has been installed successfully."
        echo "Helm version: $(helm version --short)"
    else
        echo "Failed to install Helm. Please check for errors."
        exit 1
    fi
else
    echo "Helm is already installed."
    echo "Helm version: $(helm version --short)"
fi

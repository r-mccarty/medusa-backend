#!/bin/bash

###############################################################################
# Authentication and Deployment Helper Script
# Run this script to authenticate and then deploy the Medusa backend
###############################################################################

set -e

echo "=========================================="
echo "GCP Authentication & Deployment"
echo "=========================================="
echo ""

# Check if already authenticated
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "✓ Already authenticated"
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo "  Active account: $ACCOUNT"
else
    echo "No active account found. Please authenticate..."
    echo ""
    echo "Running: gcloud auth login"
    echo ""
    gcloud auth login
fi

echo ""
echo "✓ Setting project to opticworks"
gcloud config set project opticworks

echo ""
echo "=========================================="
echo "VM Information"
echo "=========================================="

VM_NAME="instance-20251003-095148"
ZONE="us-central1-c"

echo "VM Name: $VM_NAME"
echo "Zone: $ZONE"
echo ""

# Get VM status
echo "Checking VM status..."
gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(status)" || {
    echo "ERROR: Could not describe VM. Please check if it exists."
    exit 1
}

echo ""
echo "=========================================="
echo "Ready to Deploy"
echo "=========================================="
echo ""
echo "The VM is ready. Next steps:"
echo "1. Copy setup-vm.sh to the VM"
echo "2. Run setup-vm.sh on the VM"
echo "3. Configure firewall rules"
echo "4. Deploy the Medusa application"
echo ""
read -p "Press Enter to continue with deployment or Ctrl+C to cancel..."

echo ""
echo "Copying setup scripts to VM..."
cd /home/ryan/medusa-backend

gcloud compute scp setup-vm.sh deploy.sh ecosystem.config.js .env.production.example nginx.conf \
    ${VM_NAME}:~ --zone=$ZONE

echo ""
echo "✓ Files copied to VM"
echo ""
echo "Now connecting to VM to run setup..."
echo ""

gcloud compute ssh --zone=$ZONE $VM_NAME --command "chmod +x ~/setup-vm.sh ~/deploy.sh && ~/setup-vm.sh"

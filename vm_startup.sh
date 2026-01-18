#!/usr/bin/env bash

# Exit on errors
set -e

echo "Updating and installing prerequisites..."
sudo apt update
sudo apt install -y \
    make \
    nmap \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package index..."
sudo apt update

echo "Installing Docker Engine, CLI, containerd, and Docker Compose plugin..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Enabling Docker service to start on boot..."
sudo systemctl enable docker

echo "Adding current user to the docker group..."
sudo usermod -aG docker $USER

echo "Cleaning up..."
sudo apt autoremove -y

echo
echo "Installation complete!"
echo
echo "Verify Docker:"
docker --version || true
echo
echo "Verify Docker Compose:"
docker compose version || true

echo "Reboot the system now? (y/n)"
read -r REBOOT_ANSWER
if [[ "$REBOOT_ANSWER" == "y" || "$REBOOT_ANSWER" == "Y" ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Please LOG OUT and LOG BACK IN or reboot to activate docker group membership."
    echo "Reboot skipped. Please remember to reboot later to apply changes."
fi
#!/bin/bash

# Warning message
echo "🚨  WARNING: This script is designed for Internal 'Dive Into Ansible' testing use."
echo "🚨  It is used for regression testing of the course content."
echo "🚨  Do not use this script unless you have been instructed to do so."
echo ""
echo "⏳  You have 10 seconds to cancel this script (Press Ctrl-C to abort)..."

# Countdown loop
for i in {10..1}; do
    echo "$i..."
    sleep 1
done

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root. Exiting..."
  exit 1
fi

# Allow passwordless sudo for the ansible user
echo "🔧 Configuring passwordless sudo for the ansible user..."
echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible

# 1. Download the 'tests' folder from the GitHub repository
echo "🚀 Starting the download of the 'tests' folder from the GitHub repository..."

# Ensure the folder does not exist to avoid conflicts
if [ -d "/tests" ]; then
    echo "🗑️  Removing existing '/tests' folder..."
    rm -rf /tests
fi
if [ -d "/tmp/diveintoansible-lab" ]; then
    echo "🗑️  Removing existing '/tmp/diveintoansible-lab' folder..."
    rm -rf /tmp/diveintoansible-lab
fi

# Clone only the 'tests' directory from the specified branch
echo "📥 Downloading the 'tests' folder..."
git clone --depth 1 --branch tests --filter=blob:none --sparse https://github.com/spurin/diveintoansible-lab.git /tmp/diveintoansible-lab
cd /tmp/diveintoansible-lab
git sparse-checkout set tests
sudo mv tests /tests
cd ~
sudo rm -rf /tmp/diveintoansible-lab
echo "✅ 'tests' folder successfully downloaded to '/tests'!"

# Set up SSH keys for root user
echo "🔑 Setting up SSH keys for root user..."
/utils/setup_ssh_keys.sh

# Set up SSH keys for ansible user
echo "🔑 Setting up SSH keys for ansible user..."
echo password | sudo -S -u ansible bash /utils/setup_ssh_keys.sh

# 3. Install and configure Docker
echo "🐳 Setting up Docker environment..."

# Update package list and install Docker
apt-get update && sudo apt-get install -y docker docker.io \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set Docker environment variable
export DOCKER_HOST=tcp://docker:2375

echo "✅ Docker successfully installed and configured!"

# 4. Install test requirements
echo "📦 Installing test requirements..."

pip3 install nose2 pytest docker parameterized gitpython

echo "✅ Test requirements installed!"

# 5. Run the test suite
echo "🏃‍♂️ Running the test suite with nose2..."
nose2 -vs /tests

echo "🎉 All done!"

#!/bin/bash

# Update package lists
sudo apt-get update

# Install Python and pip
sudo apt-get install -y python3 python3-pip

# Install HappyBase and Thrift
sudo pip3 install happybase thrift faker

# (Optional) Confirm install
echo "✅ Python version:"
python3 --version

echo "✅ Pip version:"
pip3 --version

echo "✅ HappyBase installed:"
pip3 show happybase

echo "✅ Setup complete."

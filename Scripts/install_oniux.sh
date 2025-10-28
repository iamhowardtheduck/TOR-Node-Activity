#!/bin/bash
set -e

# Make APT completely non-interactive
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'needrestart needrestart/restart select A'

# Install build tools and a new GCC
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libssl-dev gcc-12 g++-12

# Set gcc-12 as default
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100

# Optionally, auto-select gcc-12
sudo update-alternatives --set gcc /usr/bin/gcc-12
sudo update-alternatives --set g++ /usr/bin/g++-12

# Install Rust non-interactively (auto-accept default)
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Source cargo (add Rust to path for this session)
source "$HOME/.cargo/env"

# Install Oniux from Gitlab at specific tag
cargo install --git https://gitlab.torproject.org/tpo/core/oniux --tag v0.4.0 oniux

# Make oniux executable anywhere
sudo cp ~/.cargo/bin/oniux /usr/local/bin/

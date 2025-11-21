# ReSys-LXD

## Overview
This repository contains the configuration and scripts for the ReSys mini-project:
- Multi-tier container infrastructure using LXD
- Isolated networks for Datacenter and Application layers
- SSH key-based access between containers
- Profiles and network configurations exported for reproducibility

## Contents
- `profiles/` → LXD profiles for containers
- `networks/` → LXD network configurations
- `scripts/` → Automation scripts (if any)
- `README.md` → Project documentation

## How to use
1. Install LXD (Ubuntu 24.04/25.04)
2. Import profiles: `lxc profile edit <profile-name>`
3. Import networks: `lxc network create <network-name>`
4. Launch containers using the profiles
5. Configure SSH keys between containers

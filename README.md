# 🚀 FiveM Server Installer

Scripts for setting up a FiveM server with txAdmin and necessary components such as Apache2, phpMyAdmin, and MariaDB. These scripts automate the installation process to get your server up and running quickly.

> **Note:** This script is not associated with the official FiveM project. It is an unofficial script designed to help users install and manage a FiveM server.

## Features

- **Automatic Installation**:
  - FiveM Server with txAdmin
  - Apache2 and phpMyAdmin for managing databases
  - MariaDB setup with a secure user and database for FiveM

## Usage

To use the installation script, run the following command as root. The script will guide you through the process of installing the FiveM server, Apache2, and phpMyAdmin.

## Supported Operating Systems

| Operating System | Version | Supported |
|------------------|---------|-----------|
| **Ubuntu**       | 18.04   | ✅         |
|                  | 20.04   | ✅         |
|                  | 22.04   | ✅         |
| **Debian**       | 10      | ✅         |
|                  | 11      | ✅         |
| **Rocky Linux**  | 8       | ✅         |
|                  | 9       | ✅         |
| **AlmaLinux**    | 8       | ✅         |
|                  | 9       | ✅         |

```bash
bash <(curl -s https://raw.githubusercontent.com/luigimsn08/astro-installer/main/installer.sh)

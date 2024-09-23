# System Maintenance Script

This repository contains a Go script `system_maintenance.go` designed to optimize Ubuntu systems by performing various maintenance tasks, system checks, and optimizations. This README provides step-by-step instructions to set up the environment and execute the script, along with an overview of the benefits users will gain from running it.

---

## Table of Contents

- [Folder Structure](#folder-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [1. Prepare the Go Environment](#1-prepare-the-go-environment)
  - [2. Install Required Go Packages](#2-install-required-go-packages)
- [Running the Script](#running-the-script)
- [Benefits of the Script](#benefits-of-the-script)
- [Important Notes](#important-notes)

---

## Folder Structure

```
.
├── golang
│   ├── go.mod
│   ├── go.sum
│   ├── preparegolangenv.sh
│   ├── system_maintenance
│   └── system_maintenance.go
```

- **golang/**: The main directory containing all Go-related files.
  - **go.mod**: The Go module file specifying module path and dependencies.
  - **go.sum**: Checksums for module dependencies.
  - **preparegolangenv.sh**: Shell script to set up the Go environment.
  - **system_maintenance/**: (If this is a directory, include its contents or clarify its purpose.)
  - **system_maintenance.go**: The main Go script for system maintenance.

---

## Prerequisites

- **Operating System**: Ubuntu (or a Debian-based Linux distribution)
- **User Privileges**: Root access or `sudo` privileges
- **Internet Connection**: Required to install packages and update repositories

---

## Setup Instructions

### 1. Prepare the Go Environment

Before running the `system_maintenance.go` script, ensure that Go is installed on your system. The `preparegolangenv.sh` script automates this process.

**Steps:**

1. **Navigate to the `golang` Directory**:

   Open a terminal and navigate to the directory containing the scripts:

   ```bash
   cd /path/to/your/repository/golang
   ```

2. **Make the Setup Script Executable**:

   ```bash
   chmod +x preparegolangenv.sh
   ```

3. **Run the Setup Script**:

   ```bash
   sudo ./preparegolangenv.sh
   ```

   This script will:

   - Update the package list.
   - Install Go language if it's not already installed.
   - Set up the Go environment variables.

   **Content of `preparegolangenv.sh`**:

   ```bash
   #!/bin/bash

   # Update package list
   sudo apt-get update

   # Install Go if not installed
   if ! command -v go &> /dev/null; then
       echo "Go not found, installing..."
       sudo apt-get install -y golang
   else
       echo "Go is already installed."
   fi

   # Set up Go environment variables
   echo "Setting up Go environment variables..."
   export GOPATH=$HOME/go
   export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

   # Add environment variables to .bashrc for persistence
   echo "export GOPATH=\$HOME/go" >> ~/.bashrc
   echo "export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin" >> ~/.bashrc

   echo "Go environment setup complete."
   ```

### 2. Install Required Go Packages

The `system_maintenance.go` script relies on external Go packages specified in the `go.mod` file.

**Steps:**

1. **Ensure You Are in the `golang` Directory**:

   ```bash
   cd /path/to/your/repository/golang
   ```

2. **Initialize the Go Module**:

   The `go.mod` file should already be present. If not, initialize a new module:

   ```bash
   go mod init system_maintenance
   ```

3. **Download Dependencies**:

   ```bash
   go mod tidy
   ```

   This command will download and install all necessary packages listed in the `go.mod` file.

---

## Running the Script

Once the environment is set up and dependencies are installed, you can run the `system_maintenance.go` script.

**Steps:**

1. **Ensure You Are in the `golang` Directory**:

   ```bash
   cd /path/to/your/repository/golang
   ```

2. **Run the Script with Root Privileges**:

   ```bash
   sudo go run system_maintenance.go
   ```

   **Note**: Running as `sudo` is essential because the script performs system-level operations that require root permissions.

3. **Follow On-Screen Prompts**:

   - The script may prompt you for input, such as confirming whether to install missing services.
   - Pay attention to any warnings or errors displayed.

---

## Benefits of the Script

Running the `system_maintenance.go` script provides several benefits to enhance the performance and stability of your Ubuntu system:

1. **System Cleanup**:

   - Removes old temporary files and logs, freeing up disk space.
   - Cleans up unnecessary packages and resolves duplicate `apt` sources to prevent package management issues.

2. **System Health Checks**:

   - Collects and displays system metrics (CPU usage, memory usage, disk usage, system uptime).
   - Identifies high CPU-consuming processes and offers options to manage them.

3. **System Optimization**:

   - Optimizes the `swappiness` value to improve memory management.
   - Adjusts network settings for better performance, including buffer sizes and TCP parameters.

4. **Service Management**:

   - Verifies that critical services (e.g., `ssh`, `ufw`, `cron`) are running and properly configured.
   - Automatically disables non-essential startup services to reduce boot time and resource consumption, keeping only essential services active.

5. **Log Analysis**:

   - Scans important log files (e.g., `/var/log/syslog`, `/var/log/auth.log`) for errors and warnings.
   - Reports findings to help you identify and address potential system issues.

6. **Resource Monitoring**:

   - Displays detailed disk usage information.
   - Lists the top resource-consuming processes for further analysis.

---

## Important Notes

- **Backup Important Data**: Before running the script, ensure that you have backups of important data and configuration files.

- **Review the Script**: It's recommended to review the script to understand the actions it will perform, especially if you have customized system configurations.

- **Adjust Configurations as Needed**:

  - **Essential Services**: Modify the `essentialServices` list in the script if you have services critical to your workflow that are not already included.
  - **Log Files**: Update the `logFiles` list to include any additional logs you wish to analyze.

- **Reboot After Execution**:

  - The script suggests rebooting the system to apply all changes.
  - Plan accordingly to avoid interrupting important tasks.

- **Test Environment**:

  - If possible, test the script in a virtual machine or a non-production environment to ensure it behaves as expected.

- **Go Version**:

  - Ensure that you have a compatible version of Go installed. The script is compatible with Go 1.13 and above.

---

By following this guide, you'll be able to set up your environment and execute the `system_maintenance.go` script confidently, reaping the benefits of an optimized and well-maintained Ubuntu system.

If you encounter any issues or have questions, feel free to open an issue in the repository or reach out for support.


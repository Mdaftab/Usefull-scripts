package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/fatih/color"
	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/disk"
	"github.com/shirou/gopsutil/host"
	"github.com/shirou/gopsutil/mem"
	"github.com/shirou/gopsutil/process"
)

// ProcessInfo holds information about a system process
type ProcessInfo struct {
	PID  int32
	Name string
	CPU  float64
	MEM  float32
}

// checkRoot ensures the script is run with root privileges
func checkRoot() {
	if os.Geteuid() != 0 {
		color.Red("This script requires root privileges. Please run with sudo.")
		os.Exit(1)
	}
}

// runCommand executes a shell command and captures its output and error
func runCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		// Return a detailed error message
		return fmt.Errorf("command '%s %s' failed: %v", command, strings.Join(args, " "), err)
	}
	return nil
}

// appendToFile appends a line to a file if it doesn't already exist
func appendToFile(filePath, line string) {
	file, err := os.OpenFile(filePath, os.O_RDWR|os.O_APPEND, 0644)
	if err != nil {
		color.Red("Error opening %s: %v", filePath, err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		if scanner.Text() == line {
			return // Line already exists
		}
	}
	if _, err := file.WriteString(line + "\n"); err != nil {
		color.Red("Error writing to %s: %v", filePath, err)
	}
}

// contains checks if a slice contains a given string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// checkPrerequisites ensures all required commands are available
func checkPrerequisites() {
	color.Blue("\n[Checking Prerequisites]")
	commands := []string{"apt-get", "systemctl", "find", "df", "lsblk", "egrep"}

	for _, cmd := range commands {
		_, err := exec.LookPath(cmd)
		if err != nil {
			color.Yellow("Command '%s' not found.", cmd)
			// Attempt to install missing command if possible
			if cmd == "egrep" {
				// egrep is part of grep package
				if err := runCommand("apt-get", "install", "-y", "grep"); err != nil {
					color.Red("Failed to install grep: %v", err)
				} else {
					color.Green("Command '%s' has been installed.", cmd)
				}
			} else {
				color.Red("Please install '%s' manually.", cmd)
			}
		} else {
			color.Green("Command '%s' is available.", cmd)
		}
	}
}

// cleanupFiles removes files of a certain type older than a specified time
func cleanupFiles(path, olderThan, fileType string) {
	color.Blue("[Cleaning up %s files older than %s]", fileType, olderThan)
	err := runCommand("find", path, "-type", fileType, "-mtime", olderThan, "-delete")
	if err != nil {
		color.Red("Error cleaning up %s: %v", fileType, err)
	} else {
		color.Green("✓ %s files older than %s have been removed.", fileType, olderThan)
	}
}

// cleanupPackages removes unnecessary packages and cleans the package cache
func cleanupPackages() {
	color.Blue("\n[Cleaning up Packages]")
	// Check for duplicate apt sources
	checkAptSources()
	// Update package lists
	if err := runCommand("apt-get", "update"); err != nil {
		color.Red("Error updating package lists: %v", err)
	}
	// Upgrade packages
	if err := runCommand("apt-get", "upgrade", "-y"); err != nil {
		color.Red("Error upgrading packages: %v", err)
	}
	// Autoremove unnecessary packages
	if err := runCommand("apt-get", "autoremove", "-y"); err != nil {
		color.Red("Error removing unnecessary packages: %v", err)
	}
	// Clean package cache
	if err := runCommand("apt-get", "clean"); err != nil {
		color.Red("Error cleaning package cache: %v", err)
	}
}

// getSystemInfo gathers system CPU, memory, disk, and uptime information
func getSystemInfo() (float64, float64, float64, time.Duration, error) {
	// Get CPU usage
	cpuPercent, err := cpu.Percent(time.Second, false)
	if err != nil {
		return 0, 0, 0, 0, fmt.Errorf("error fetching CPU percentage: %v", err)
	}

	// Get memory usage
	memInfo, err := mem.VirtualMemory()
	if err != nil {
		return 0, 0, 0, 0, fmt.Errorf("error fetching memory information: %v", err)
	}

	// Get disk usage
	diskInfo, err := disk.Usage("/")
	if err != nil {
		return 0, 0, 0, 0, fmt.Errorf("error fetching disk usage: %v", err)
	}

	// Get uptime
	hostInfo, err := host.Info()
	if err != nil {
		return 0, 0, 0, 0, fmt.Errorf("error fetching host information: %v", err)
	}
	uptime := time.Duration(hostInfo.Uptime) * time.Second

	return cpuPercent[0], memInfo.UsedPercent, diskInfo.UsedPercent, uptime, nil
}

// getTopProcesses retrieves the top n processes by CPU usage
func getTopProcesses(n int) []ProcessInfo {
	processes, _ := process.Processes()
	var wg sync.WaitGroup
	var mu sync.Mutex
	var processInfos []ProcessInfo

	wg.Add(len(processes))

	for _, p := range processes {
		go func(p *process.Process) {
			defer wg.Done()
			// Get CPU and memory usage for each process
			cpu, _ := p.CPUPercent()
			mem, _ := p.MemoryPercent()
			name, _ := p.Name()

			mu.Lock()
			processInfos = append(processInfos, ProcessInfo{p.Pid, name, cpu, mem})
			mu.Unlock()
		}(p)
	}

	wg.Wait()
	// Sort processes by CPU usage
	sort.Slice(processInfos, func(i, j int) bool {
		return processInfos[i].CPU > processInfos[j].CPU
	})
	if len(processInfos) > n {
		return processInfos[:n]
	}
	return processInfos
}

// analyzeCPU checks CPU usage and provides options to handle high usage
func analyzeCPU(cpuUsage float64) {
	color.Blue("\n[CPU Analysis]")
	if cpuUsage > 85 {
		color.Red("! Warning: CPU usage is high (%.2f%%)", cpuUsage)
		color.Yellow("\nTop 5 CPU-consuming processes:")

		topProcesses := getTopProcesses(5)
		for _, p := range topProcesses {
			fmt.Printf("PID: %d, Name: %s, CPU: %.2f%%, Memory: %.2f%%\n", p.PID, p.Name, p.CPU, p.MEM)
		}

		var choice string
		fmt.Print(color.YellowString("\nDo you want to kill any of these processes? (y/n): "))
		fmt.Scanln(&choice)
		if strings.ToLower(choice) == "y" {
			fmt.Print(color.YellowString("Enter the PID of the process to kill: "))
			fmt.Scanln(&choice)
			pidToKill, err := strconv.Atoi(choice)
			if err != nil {
				color.Red("Invalid PID entered.")
				return
			}
			if err := runCommand("kill", "-9", strconv.Itoa(pidToKill)); err != nil {
				color.Red("Failed to terminate process with PID %d: %v", pidToKill, err)
			} else {
				color.Green("Process with PID %d has been terminated.", pidToKill)
			}
		}
	} else {
		color.Green("✓ CPU usage is normal (%.2f%%)", cpuUsage)
	}
}

// optimizeSwappiness adjusts the swappiness value for better performance
func optimizeSwappiness() {
	color.Blue("\n[Optimizing Swappiness]")
	const swappinessFile = "/proc/sys/vm/swappiness"
	content, err := ioutil.ReadFile(swappinessFile)
	if err != nil {
		color.Red("Error reading swappiness: %v", err)
		return
	}

	currentSwappiness, err := strconv.Atoi(strings.TrimSpace(string(content)))
	if err != nil {
		color.Red("Error parsing swappiness: %v", err)
		return
	}

	if currentSwappiness != 10 {
		// Set swappiness to 10
		if err := ioutil.WriteFile(swappinessFile, []byte("10"), 0644); err != nil {
			color.Red("Error setting swappiness: %v", err)
		} else {
			color.Green("✓ Swappiness set to 10 for better performance")
			// Make the change persistent
			runCommand("sysctl", "-w", "vm.swappiness=10")
			appendToFile("/etc/sysctl.conf", "vm.swappiness=10")
		}
	} else {
		color.Green("✓ Swappiness is already optimized")
	}
}

// optimizeNetworkSettings adjusts network parameters for better performance
func optimizeNetworkSettings() {
	color.Blue("\n[Optimizing Network Settings]")
	settings := map[string]string{
		"net.core.rmem_max":           "16777216",
		"net.core.wmem_max":           "16777216",
		"net.ipv4.tcp_rmem":           "4096 87380 16777216",
		"net.ipv4.tcp_wmem":           "4096 65536 16777216",
		"net.ipv4.tcp_fin_timeout":    "15",
		"net.ipv4.tcp_keepalive_time": "300",
	}

	for key, value := range settings {
		if err := runCommand("sysctl", "-w", fmt.Sprintf("%s=%s", key, value)); err != nil {
			color.Red("Error optimizing %s: %v", key, err)
		} else {
			color.Green("✓ Optimized %s", key)
			appendToFile("/etc/sysctl.conf", fmt.Sprintf("%s=%s", key, value))
		}
	}
}

// checkAptSources identifies and removes duplicate entries in apt sources
func checkAptSources() {
	color.Blue("\n[Checking for duplicate apt sources]")
	// Get list of source list files
	files, err := ioutil.ReadDir("/etc/apt/sources.list.d/")
	if err != nil {
		color.Red("Error reading sources.list.d directory: %v", err)
		return
	}

	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".list") {
			checkAndFixDuplicateEntries("/etc/apt/sources.list.d/" + file.Name())
		}
	}
}

// checkAndFixDuplicateEntries checks a single file for duplicate lines and removes them
func checkAndFixDuplicateEntries(filePath string) {
	file, err := os.Open(filePath)
	if err != nil {
		color.Red("Error opening %s: %v", filePath, err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lines := make([]string, 0)
	seenLines := make(map[string]bool)

	for scanner.Scan() {
		line := scanner.Text()
		if !seenLines[line] {
			seenLines[line] = true
			lines = append(lines, line)
		} else {
			color.Yellow("Duplicate entry found and removed in %s: %s", filePath, line)
		}
	}

	if err := scanner.Err(); err != nil {
		color.Red("Error reading %s: %v", filePath, err)
		return
	}

	// Write the unique lines back to the file
	if err := ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")+"\n"), 0644); err != nil {
		color.Red("Error writing to %s: %v", filePath, err)
	}
}

// checkServices verifies the status of critical services
func checkServices() {
	color.Blue("\n[Checking System Services]")
	services := []string{"ssh", "ufw", "cron"} // Add or remove services as needed

	for _, service := range services {
		// Check if the service exists
		err := exec.Command("systemctl", "status", service).Run()
		if err != nil {
			// If the service doesn't exist, offer to install it
			if strings.Contains(err.Error(), "could not be found") || strings.Contains(err.Error(), "not found") {
				color.Yellow("Service %s is not installed.", service)
				fmt.Printf("Do you want to install %s? (y/n): ", service)
				var choice string
				fmt.Scanln(&choice)
				if strings.ToLower(choice) == "y" {
					if err := runCommand("apt-get", "install", "-y", service); err != nil {
						color.Red("Failed to install %s: %v", service, err)
					} else {
						color.Green("Service %s has been installed.", service)
					}
				}
				continue
			} else {
				color.Red("Error checking status of %s: %v", service, err)
				continue
			}
		}

		// Check if the service is active
		err = exec.Command("systemctl", "is-active", "--quiet", service).Run()
		if err != nil {
			color.Red("Service %s is not running.", service)
			// Try to start the service
			if err := runCommand("systemctl", "start", service); err != nil {
				color.Red("Failed to start service %s: %v", service, err)
			} else {
				color.Green("Service %s started.", service)
			}
		} else {
			color.Green("Service %s is running.", service)
		}
	}
}

// optimizeStartupServices identifies and automatically disables unnecessary startup services
func optimizeStartupServices() {
	color.Blue("\n[Optimizing Startup Services]")
	// List all enabled services
	cmd := exec.Command("systemctl", "list-unit-files", "--type=service", "--state=enabled")
	output, err := cmd.Output()
	if err != nil {
		color.Red("Error listing enabled services: %v", err)
		return
	}
	services := strings.Split(strings.TrimSpace(string(output)), "\n")

	// List of essential services to keep
	essentialServices := []string{
		"ssh", "cron", "networking", "dbus", "rsyslog", "systemd-journald",
		"docker", "docker-registry", // Add other essential services as needed
	}

	for _, line := range services {
		fields := strings.Fields(line)
		if len(fields) >= 2 && fields[1] == "enabled" {
			serviceName := strings.TrimSuffix(fields[0], ".service")

			// Skip essential services
			if contains(essentialServices, serviceName) {
				color.Green("Keeping essential service: %s", serviceName)
				continue
			}

			// Automatically disable the service
			if err := runCommand("systemctl", "disable", serviceName); err != nil {
				color.Red("Failed to disable %s: %v", serviceName, err)
			} else {
				color.Yellow("Service %s has been disabled.", serviceName)
			}
		}
	}
}

// analyzeLogs scans log files for errors and warnings
func analyzeLogs() {
	color.Blue("\n[Analyzing Log Files]")
	logFiles := []string{"/var/log/syslog", "/var/log/auth.log"} // Add more log files as needed
	for _, logFile := range logFiles {
		color.Yellow("Scanning %s for errors and warnings...", logFile)
		cmd := exec.Command("egrep", "-i", "error|warning", logFile)
		output, err := cmd.CombinedOutput()
		if err != nil {
			// egrep returns exit status 1 if no lines were selected
			if exitError, ok := err.(*exec.ExitError); ok && exitError.ExitCode() == 1 {
				color.Green("No errors or warnings found in %s.", logFile)
			} else {
				color.Red("Error scanning %s: %v", logFile, err)
			}
		} else {
			if len(output) > 0 {
				fmt.Printf("Errors/Warnings found in %s:\n%s\n", logFile, string(output))
			} else {
				color.Green("No errors or warnings found in %s.", logFile)
			}
		}
	}
}

func main() {
	// Ensure the script is run as root
	checkRoot()

	// Check for required commands
	checkPrerequisites()

	color.Cyan("==================================")
	color.Cyan("   System Optimization Script")
	color.Cyan("==================================")

	// Clean up old temp and log files
	cleanupFiles("/tmp", "+7", "f")
	cleanupFiles("/var/log", "+2", "f")

	// Perform system health checks
	color.Blue("\n[System Health Check]")
	cpuUsage, memUsage, diskUsage, uptime, err := getSystemInfo()
	if err != nil {
		color.Red("Error fetching system info: %v", err)
		return
	}
	color.Yellow("CPU Usage:    %.2f%%", cpuUsage)
	color.Yellow("Memory Usage: %.2f%%", memUsage)
	color.Yellow("Disk Usage:   %.2f%%", diskUsage)
	color.Yellow("System Uptime: %v", uptime)

	// Analyze CPU usage
	analyzeCPU(cpuUsage)

	// Optimize swappiness for memory usage
	optimizeSwappiness()

	// Optimize network settings
	optimizeNetworkSettings()

	// Clean up packages and check apt sources
	cleanupPackages()

	// Check system services
	checkServices()

	// Optimize startup services
	optimizeStartupServices()

	// Analyze log files
	analyzeLogs()

	// Disk usage details
	color.Blue("\n[Disk Usage Details]")
	runCommand("df", "-h")

	// Top 5 resource-consuming processes
	color.Blue("\n[Top 5 Resource-Consuming Processes]")
	topProcesses := getTopProcesses(5)
	for _, p := range topProcesses {
		fmt.Printf("PID: %-6d | Name: %-20s | CPU: %6.2f%% | Memory: %6.2f%%\n", p.PID, p.Name, p.CPU, p.MEM)
	}

	color.Cyan("\n==================================")
	color.Green("System optimization completed.")
	color.Yellow("Please reboot your system to apply all changes.")
	color.Cyan("==================================")
}

#!/bin/bash
# System Performance Monitoring Script
# Author: Aftab
# Version: 3.1
# Description: This script checks system performance metrics, compares them with expected values, and provides recommendations.

# Function to get number of CPU cores
get_cpu_cores() {
    local cpu_cores
    cpu_cores=$(nproc)
    echo "$cpu_cores"
}

# Get CPU cores and set initial thresholds
CPU_CORES=$(get_cpu_cores)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
LOAD_AVG_THRESHOLD=$(echo "scale=2; 0.7 * $CPU_CORES" | bc)  # 70% per core
IO_WAIT_THRESHOLD=5.0
SWAP_USAGE_THRESHOLD=50
OPEN_FD_THRESHOLD=100000
INODE_THRESHOLD=80
TEMP_THRESHOLD=75

# Function to check CPU usage per core
check_cpu_usage() {
    local cpu_usage total_cpu=0
    # Get CPU usage for each core and calculate average
    for i in $(seq 1 $CPU_CORES); do
        local core_usage
        core_usage=$(mpstat -P ALL 1 1 | grep "Average.*all" | awk '{print 100-$NF}')
        total_cpu=$(echo "$total_cpu + $core_usage" | bc)
    done
    cpu_usage=$(echo "scale=2; $total_cpu / $CPU_CORES" | bc)
    if [[ ! $cpu_usage =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        cpu_usage=0
    fi
    echo "$cpu_usage"
}

# Function to check Memory usage
check_memory_usage() {
    local memory_usage
    memory_usage=$(free | awk '/Mem:/ {printf "%.2f", ($2-$7)/$2 * 100}')
    echo "$memory_usage"
}

# Function to check Swap usage
check_swap_usage() {
    local swap_usage
    swap_total=$(free | awk '/Swap:/ {print $2}')
    if [ "$swap_total" -eq 0 ]; then
        echo "0"
    else
        swap_usage=$(free | awk '/Swap:/ {printf "%.2f", $3/$2 * 100}')
        echo "$swap_usage"
    fi
}

# Function to check Disk usage
check_disk_usage() {
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# Function to check Load Average with CPU core awareness
check_load_average() {
    local load_avg normalized_load
    load_avg=$(cat /proc/loadavg | awk '{print $1}')
    normalized_load=$(echo "scale=2; $load_avg / $CPU_CORES" | bc)
    echo "$normalized_load"
}

# Function to check I/O wait time
check_io_usage() {
    local io_wait
    io_wait=$(vmstat 1 2 | awk 'END {print $16}')  # Column 16 is I/O wait in vmstat
    if [[ ! $io_wait =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        io_wait=0
    fi
    echo "$io_wait"
}

# Function to check Network statistics
check_network_usage() {
    local network_usage
    network_usage=$(ss -s | grep "TCP:" | awk '{print $2, $3, $4, $5}')
    echo "$network_usage"
}

# Function to check System Uptime
check_system_uptime() {
    local uptime
    uptime=$(uptime -p)
    echo "$uptime"
}

# Function to check Open File Descriptors
check_open_fds() {
    local open_fds
    open_fds=$(cat /proc/sys/fs/file-nr | awk '{print $1}')
    echo "$open_fds"
}

# Function to check Inode Usage
check_inode_usage() {
    local inode_usage
    inode_usage=$(df -i / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$inode_usage"
}

# Function to check System Temperature
check_system_temperature() {
    local temperature
    temperature=$(sensors | grep 'Core 0' | awk '{print $3}' | sed 's/+//g; s/°C//g')
    if [[ -z "$temperature" ]]; then
        temperature=0
    fi
    echo "$temperature"
}

# Collect current system stats
cpu_usage=$(check_cpu_usage)
memory_usage=$(check_memory_usage)
disk_usage=$(check_disk_usage)
load_avg=$(check_load_average)
io_wait=$(check_io_usage)
swap_usage=$(check_swap_usage)
network_usage=$(check_network_usage)
uptime=$(check_system_uptime)
open_fds=$(check_open_fds)
inode_usage=$(check_inode_usage)
temperature=$(check_system_temperature)

# Print summary table
printf "\n%-20s %-20s %-20s %-20s\n" "Metric" "Current Value" "Expected Value" "Status"
printf "%-20s %-20s %-20s %-20s\n" "--------------------" "--------------------" "--------------------" "--------------------"

printf "%-20s %-20s\n" "CPU Cores" "$CPU_CORES"
printf "%-20s %-20s %-20s %-20s\n" "CPU Usage (%)" "$cpu_usage" "$CPU_THRESHOLD" "$( [ "$(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l)" -eq 1 ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "Memory Usage (%)" "$memory_usage" "$MEMORY_THRESHOLD" "$( [ "$(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l)" -eq 1 ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "Disk Usage (%)" "$disk_usage" "$DISK_THRESHOLD" "$( [ "$disk_usage" -gt "$DISK_THRESHOLD" ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "Load Average (per core)" "$load_avg" "$LOAD_AVG_THRESHOLD" "$( [ "$(echo "$load_avg > $LOAD_AVG_THRESHOLD" | bc -l)" -eq 1 ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "I/O Wait (%)" "$io_wait" "$IO_WAIT_THRESHOLD" "$( [ "$(echo "$io_wait > $IO_WAIT_THRESHOLD" | bc -l)" -eq 1 ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "Swap Usage (%)" "$swap_usage" "$SWAP_USAGE_THRESHOLD" "$( [ "$(echo "$swap_usage > $SWAP_USAGE_THRESHOLD" | bc -l)" -eq 1 ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "Open File Descriptors" "$open_fds" "$OPEN_FD_THRESHOLD" "$( [ "$open_fds" -gt "$OPEN_FD_THRESHOLD" ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "Inode Usage (%)" "$inode_usage" "$INODE_THRESHOLD" "$( [ "$inode_usage" -gt "$INODE_THRESHOLD" ] && echo "High" || echo "Normal")"
printf "%-20s %-20s %-20s %-20s\n" "System Temperature (°C)" "$temperature" "$TEMP_THRESHOLD" "$( [ "$temperature" -gt "$TEMP_THRESHOLD" ] && echo "High" || echo "Normal")"

# Provide recommendations based on CPU cores and normalized values
if [ "$(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l)" -eq 1 ]; then
    echo "Recommendation: High CPU usage detected across $CPU_CORES cores. Consider reducing CPU load or distributing tasks."
fi

if [ "$(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l)" -eq 1 ]; then
    echo "Recommendation: Consider freeing up memory or increasing RAM."
fi

if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
    echo "Recommendation: Consider cleaning up disk space."
fi

if [ "$(echo "$load_avg > $LOAD_AVG_THRESHOLD" | bc -l)" -eq 1 ]; then
    echo "Recommendation: High load average per core detected, consider optimizing processes or adding more cores."
fi

if [ "$(echo "$io_wait > $IO_WAIT_THRESHOLD" | bc -l)" -eq 1 ]; then
    echo "Recommendation: High I/O wait time, check disk performance and I/O patterns."
fi

if [ "$(echo "$swap_usage > $SWAP_USAGE_THRESHOLD" | bc -l)" -eq 1 ]; then
    echo "Recommendation: High swap usage, consider adding more RAM or adjusting swappiness."
fi

if [ "$open_fds" -gt "$OPEN_FD_THRESHOLD" ]; then
    echo "Recommendation: High number of open file descriptors, check for leaks."
fi

if [ "$inode_usage" -gt "$INODE_THRESHOLD" ]; then
    echo "Recommendation: High inode usage, consider cleaning small files."
fi

if [ "$temperature" -gt "$TEMP_THRESHOLD" ]; then
    echo "Recommendation: High system temperature, check cooling and airflow."
fi
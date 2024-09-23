#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${MAGENTA}$1${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package
install_package() {
    if ! command_exists sudo; then
        echo -e "${RED}Error: sudo is not available. Please run this script with root privileges or install required packages manually.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Installing $1...${NC}"
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y "$1" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to install $1. Please install it manually.${NC}"
        exit 1
    fi
    echo -e "${GREEN}$1 installed successfully.${NC}"
}

# Check and install required packages
required_packages=("traceroute" "whois" "curl" "dnsutils" "openssl")
for package in "${required_packages[@]}"; do
    if ! command_exists "$package"; then
        install_package "$package"
    fi
done

# Prompt for website
read -p "Enter the website to analyze (e.g., www.example.com): " website

# Remove protocol if present and extract domain
domain=$(echo "$website" | sed -E 's#^https?://##' | cut -d/ -f1)

# Validate input
if [ -z "$domain" ]; then
    echo -e "${RED}Error: Website name cannot be empty.${NC}"
    exit 1
fi

echo -e "\n${GREEN}Analyzing $domain...${NC}"

# IP Address and Reverse DNS
print_header "IP Address and Reverse DNS"
ip_address=$(dig +short $domain | tail -n1)
if [ -n "$ip_address" ]; then
    reverse_dns=$(dig +short -x $ip_address)
    echo -e "${CYAN}IP Address: ${NC}$ip_address"
    echo -e "${CYAN}Reverse DNS: ${NC}$reverse_dns"
else
    echo -e "${RED}Unable to resolve IP address${NC}"
fi

# A Records
print_header "A Records"
dig +short $domain A | sed "s/^/${CYAN}  /"

# AAAA Records
print_header "AAAA Records (IPv6)"
aaaa_records=$(dig +short $domain AAAA)
if [ -z "$aaaa_records" ]; then
    echo -e "${RED}  No AAAA records found${NC}"
else
    echo "$aaaa_records" | sed "s/^/${CYAN}  /"
fi

# MX Records
print_header "MX Records"
mx_records=$(dig +short $domain MX)
if [ -z "$mx_records" ]; then
    echo -e "${RED}  No MX records found${NC}"
else
    echo "$mx_records" | sed "s/^/${CYAN}  /"
fi

# CAA Records
print_header "CAA Records"
caa_records=$(dig +short $domain CAA)
if [ -z "$caa_records" ]; then
    echo -e "${RED}  No CAA records found${NC}"
else
    echo "$caa_records" | sed "s/^/${CYAN}  /"
fi

# NS Records
print_header "NS Records"
dig +short $domain NS | sed "s/^/${CYAN}  /"

# TXT Records
print_header "TXT Records"
dig +short $domain TXT | sed "s/^/${CYAN}  /"

# DMARC Record
print_header "DMARC Record"
dmarc_record=$(dig +short _dmarc.$domain TXT)
if [ -z "$dmarc_record" ]; then
    echo -e "${RED}  No DMARC record found${NC}"
else
    echo "$dmarc_record" | sed "s/^/${CYAN}  /"
fi

# SPF Record
print_header "SPF Record"
spf_record=$(dig +short $domain TXT | grep "v=spf1")
if [ -z "$spf_record" ]; then
    echo -e "${RED}  No SPF record found${NC}"
else
    echo "$spf_record" | sed "s/^/${CYAN}  /"
fi

# Traceroute
print_header "Traceroute (Hops)"
traceroute -m 15 $domain | sed "s/^/  /"

# Latency
print_header "Latency"
ping -c 5 $domain | tail -n1 | awk -v CYAN="$CYAN" -v NC="$NC" '{print CYAN "  " $4 " " $5 NC}' | sed 's/\// Average: /'

# WHOIS Information
print_header "WHOIS Information"
whois $domain | grep -E "Domain Name:|Registrar:|Creation Date:|Expiration Date:|Name Server:" | sed "s/^/${CYAN}  /"

# SSL Certificate Information
print_header "SSL Certificate Information"
echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates -issuer -subject | sed "s/^/${CYAN}  /"

# SSL/TLS Protocols and Ciphers
print_header "Supported SSL/TLS Protocols"
for protocol in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
    result=$(openssl s_client -$protocol -connect $domain:443 < /dev/null 2>&1)
    if [[ $result == *"CONNECTED"* ]]; then
        echo -e "${CYAN}  $protocol: ${GREEN}Supported${NC}"
    else
        echo -e "${CYAN}  $protocol: ${RED}Not supported${NC}"
    fi
done

# Check for HTTP/2 support
print_header "HTTP/2 Support"
http2_support=$(curl -sI --http2 -o /dev/null -w '%{http_version}\n' "https://$domain")
if [[ $http2_support == "2" ]]; then
    echo -e "${CYAN}  HTTP/2 is ${GREEN}supported${NC}"
else
    echo -e "${CYAN}  HTTP/2 is ${RED}not supported${NC}"
fi

echo -e "\n${GREEN}Analysis complete!${NC}"
#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${MAGENTA}$1${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
}

# Function to print records
print_records() {
    local record_type=$1
    local records=$2
    if [ -n "$records" ]; then
        print_header "$record_type Records"
        echo "$records" | sed "s/^/${CYAN}  /"
    else
        echo -e "${RED}  No $record_type records found${NC}"
    fi
}

# Function to check for HTTP/2 support
check_http2_support() {
    local domain=$1
    local http2_support=$(curl -sI --http2 -o /dev/null -w '%{http_version}\n' "https://$domain")
    if [[ $http2_support == "2" ]]; then
        echo -e "${CYAN}  HTTP/2 is ${GREEN}supported${NC}"
    else
        echo -e "${CYAN}  HTTP/2 is ${RED}not supported${NC}"
    fi
}

# Main script
domain=$1
if [ -z "$domain" ]; then
    echo -e "${RED}Error: Domain name is required${NC}"
    exit 1
fi

# TXT Records
txt_records=$(dig +short $domain TXT)
print_records "TXT" "$txt_records"

# DMARC Record
dmarc_record=$(dig +short _dmarc.$domain TXT)
print_records "DMARC" "$dmarc_record"

# SPF Record
spf_record=$(dig +short $domain TXT | grep "v=spf1")
print_records "SPF" "$spf_record"

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
for protocol in tls1 tls1_1 tls1_2 tls1_3; do
    echo -e "${CYAN}  Checking $protocol...${NC}"
    result=$(openssl s_client -$protocol -connect $domain:443 < /dev/null 2>&1)
    if echo "$result" | grep -q "CONNECTED"; then
        echo -e "${GREEN}  $protocol is supported${NC}"
    else
        echo -e "${RED}  $protocol is not supported${NC}"
        echo -e "${RED}  Error: $result${NC}"
    fi
done


git config --global user.email "alam156@gmail.com"
  git config --global user.name "Md Aftab"
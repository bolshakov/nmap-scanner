# Nmap Scanner

This app scans given server for open ports and notify by email if forbidden open port found.

## Usage

Command accept two arguments -- server address and whitelisted ports in the following format:

* `22/tcp`
* `80/tcp`
* `53/udp`
* `22/tcp,80/tcp,53/udp`
* etc

To configure notification options the number of environment variables available. Docker compose example:

```yml
version: '3'

services:
  scanner:
    image: bolshakov/nmap-scanner:latest
    restart: always
    command: myserver.example.com 22/tcp,80/tcp
    environment:
      - SCAN_INTERVAL=3600 # in seconds (default 3600)
      - SCAN_PORTS=1-100 # or just single oport, e.g 22 (default 1-65535)
      - SMTP_USERNAME=nmap-scanner
      - SMTP_PASSWORD=secret123
      - SMTP_HOST=smtp.example.com
      - SMTP_PORT=587
      - EMAIL_FROM=nmap-scanner@example.com
      - EMAIL_TO=warnings@example.com
``` 

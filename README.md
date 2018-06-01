# Nmap Scanner

This app scans given server for open ports and notify by email if forbidden open port found.

## Usage

Command accept two arguments -- server address and whitelisted ports in the following format:

* `22/tcp`
* `80/tcp`
* `53/udp`
* `22/tcp,80/tcp,53/udp`
* etc

Two configure notification options the number of environment variables available. Docker compose example:

```yml
version: '3'

services:
  scanner:
    image: bolshakov/nmap-scanner:latest
    restart: always
    command: myserver.example.com 22/tcp,80/tcp
    environment:
      - SCAN_INTERVAL=3600 # in seconds
      - SCAN_PORT_RANGE=1-65535
      - EMAIL_SMTP_HOST=smtp.example.com
      - EMAIL_SMTP_PORT=587
      - EMAIL_FROM=nmap-scanner@example.com
      - EMAIL_USERNAME=nmap-scanner
      - EMAIL_PASSWORD=secret123
      - NOTIFY_TO_EMAIL=warnings@example.com      
``` 

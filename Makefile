all: build

build:
	docker build -t bolshakov/nmap-scanner .
	docker push bolshakov/nmap-scanner
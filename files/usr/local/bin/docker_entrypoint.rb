#!/usr/bin/env ruby
require 'open3'

DEFAULT_SCAN_INTERVAL = 60*60
DEFAULT_PORT_RANGE = '1-65535'

scan_interval = ENV.fetch('SCAN_INTERVAL') do
  puts "Scan interval set to #{DEFAULT_SCAN_INTERVAL} seconds."
  DEFAULT_SCAN_INTERVAL
end

scan_port_range = ENV.fetch('SCAN_PORT_RANGE') do
  puts "Scan port range set to #{DEFAULT_PORT_RANGE}."
  DEFAULT_PORT_RANGE
end

ENV.fetch('EMAIL_SMTP_HOST') { raise 'EMAIL_SMTP_HOST environment variable missing' }
ENV.fetch('EMAIL_SMTP_PORT') { raise 'EMAIL_SMTP_PORT environment variable missing' }
ENV.fetch('EMAIL_FROM') { raise 'EMAIL_FROM environment variable missing' }
ENV.fetch('EMAIL_USERNAME') { raise 'EMAIL_USERNAME environment variable missing' }
ENV.fetch('EMAIL_PASSWORD') { raise 'EMAIL_PASSWORD environment variable missing' }
ENV.fetch('NOTIFY_TO_EMAIL') { raise 'NOTIFY_TO_EMAIL environment variable missing' }

server_address = ARGV.fetch(0) { raise 'First argument should be server address' }
whitelisted_ports = String(ARGV[1]).split(',')

if whitelisted_ports.empty?
  raise 'Second argument should be list of allowed ports in the following format: 80/tcp,443/udp'
end

MESSAGE_TEMPLATE = <<-MESSAGE
  Subject: [nmap-scanner] Forbidden port found

  The following forbidden open ports was found %{extra_ports} on #{server_address}.

  Whitelisted ports: #{whitelisted_ports.join(', ')}
  Opened ports: %{opened_ports}
MESSAGE

puts `confd -onetime -backend env`

def scan(server_address, port_range, whitelisted_ports)
  scan_result = `nmap -p #{port_range} #{server_address}`.split("\n")
  open_ports = scan_result.select { |string| string.match?(/\d+\/tcp|udp/) }.map { |line| line.split(/\s+/).first }

  extra_ports = open_ports - whitelisted_ports

  if extra_ports.empty?
    puts 'ok'
  else
    puts "forbidden ports found #{extra_ports.join(', ')}"
    Open3.popen2e("msmtp -a gmail #{ENV['NOTIFY_TO_EMAIL']}") do |stdin, _, _|
      message = format(MESSAGE_TEMPLATE, extra_ports: extra_ports.join(', '), opened_ports: open_ports.join(', '))
      stdin.puts(message)
      stdin.close
    end
  end
end

trap('SIGINT') { exit! }

loop do
  print "Scanning server #{server_address}: "
  scan(server_address, scan_port_range, whitelisted_ports)
  sleep(scan_interval.to_i)
end
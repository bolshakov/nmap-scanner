#!/usr/bin/env ruby
require 'mail'
require 'net/smtp'
require 'ostruct'
require 'logger'
require 'timeout'

DEFAULT_SCAN_INTERVAL = 60*60
DEFAULT_NMAP_OPTIONS = '-F'

Settings = OpenStruct.new(
  nmap_options: ENV.fetch('NMAP_OPTIONS', DEFAULT_NMAP_OPTIONS),
  scan_interval: ENV.fetch('SCAN_INTERVAL', DEFAULT_SCAN_INTERVAL).to_i,
  smtp_host: ENV.fetch('SMTP_HOST') { raise 'EMAIL_SMTP_HOST environment variable missing' },
  smtp_port: Integer(ENV.fetch('SMTP_PORT') { raise 'EMAIL_SMTP_PORT environment variable missing' }),
  smtp_username: ENV.fetch('SMTP_USERNAME') { raise 'EMAIL_USERNAME environment variable missing' },
  smtp_password: ENV.fetch('SMTP_PASSWORD') { raise 'EMAIL_PASSWORD environment variable missing' },
  email_from: ENV.fetch('EMAIL_FROM') { raise 'EMAIL_FROM environment variable missing' },
  email_to: ENV.fetch('EMAIL_TO') { raise 'NOTIFY_TO_EMAIL environment variable missing' },
  server_address: ARGV.fetch(0) { raise 'First argument should be server address' },
  whitelisted_ports: String(ARGV[1]).split(',').tap { |whitelisted_ports|
    if whitelisted_ports.empty?
      raise 'Second argument should be list of allowed ports in the following format: 80/tcp,443/udp'
    end
  },
)

class NmapScanner
  def initialize(settings, logger)
    @logger = logger
    @settings = settings

    log(:debug, "[Settings] scan_interval=#{settings.scan_interval}")
    log(:debug, "[Settings] nmap_options=#{settings.nmap_options}")
    log(:debug, "[Settings] smtp_host=#{settings.smtp_host}")
    log(:debug, "[Settings] smtp_port=#{settings.smtp_port}")
    log(:debug, "[Settings] smtp_username=#{settings.smtp_username}")
    log(:debug, "[Settings] smtp_password=#{settings.smtp_password}")
    log(:debug, "[Settings] email_from=#{settings.email_from}")
    log(:debug, "[Settings] email_to=#{settings.email_to}")
    log(:debug, "[Settings] server_address=#{settings.server_address}")
    log(:debug, "[Settings] whitelisted_ports=#{settings.whitelisted_ports}")
  end
  attr_reader :settings

  MESSAGE_TEMPLATE = <<-MESSAGE
    The following forbidden open ports was found %{extra_ports} on %{server_address}.

    Whitelisted ports: %{whitelisted_ports}
    Opened ports: %{opened_ports}
  MESSAGE

  def run
    loop do
      Timeout.timeout(settings.scan_interval) { scan_and_notify }
    rescue Timeout::Error
      log(:error, "Scanning took more then #{settings.scan_interval} seconds. Terminating... ")
    rescue => error
      log(:error, "Unexpected error happened: #{error.inspect}")
      retry
    ensure
      log(:info, "")
      sleep(settings.scan_interval.to_i)
    end
  end

  private def scan_and_notify
    open_ports = find_open_ports
    extra_ports = open_ports - settings.whitelisted_ports

    if extra_ports.empty?
      log(:info, "No forbidden ports found.")
    else
      log(:info, "Forbidden ports found #{extra_ports.join(', ')}")
      notify_by_email(open_ports, extra_ports)
    end
  end

  private def find_open_ports
    nmap_command = "nmap #{settings.nmap_options} #{settings.server_address}"
    log(:debug, "Running nmap: #{nmap_command}")
    scan_result = `#{nmap_command}`.split("\n")

    scan_result
      .select { |string| string.match?(/\d+\/tcp|udp/) }
      .map { |line| line.split(/\s+/).first }
  end

  private def notify_by_email(open_ports, extra_ports)
    message_string = mail_message_string(open_ports, extra_ports)

    smtp = Net::SMTP.new(settings.smtp_host, settings.smtp_port)
    smtp.enable_starttls
    result = smtp.start('localhost', settings.smtp_username, settings.smtp_password, :login) do |smtp|
      smtp.send_message(message_string, settings.email_from, settings.email_to)
    end

    log(:debug, "Notification message sent, success=#{result.success?}")
  end

  private def mail_message_string(open_ports, extra_ports)
    message = format(MESSAGE_TEMPLATE,
      extra_ports: extra_ports.join(', '),
      opened_ports: open_ports.join(', '),
      server_address: settings.server_address,
      whitelisted_ports: settings.whitelisted_ports.join(', '),
    )

    Mail.new.tap do |mail|
      mail.from = settings.email_from
      mail.to = settings.email_to
      mail.subject = '[nmap-scanner] Forbidden port found'
      mail.body = message
    end.to_s
  end

  private def log(severity, message)
    @logger.send(severity, "[#{settings.server_address}] #{message}")
  end
end


trap('SIGINT') { exit! }

$stdout.sync = true
logger = Logger.new($stdout)
logger.level = Logger::DEBUG
NmapScanner.new(Settings, logger).run
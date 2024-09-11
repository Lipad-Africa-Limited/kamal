class Kamal::Configuration::Proxy
  include Kamal::Configuration::Validation

  DEFAULT_HTTP_PORT = 80
  DEFAULT_HTTPS_PORT = 443
  DEFAULT_IMAGE = "basecamp/kamal-proxy:latest"
  DEFAULT_LOG_REQUEST_HEADERS = [ "Cache-Control", "Last-Modified" ]

  delegate :argumentize, :optionize, to: Kamal::Utils

  def initialize(config:)
    @proxy_config = config.raw_config.proxy || {}
    validate! proxy_config, with: Kamal::Configuration::Validator::Proxy
  end

  def enabled?
    !!proxy_config.fetch("enabled", false)
  end

  def hosts
    if enabled?
      proxy_config.fetch("hosts", [])
    else
      []
    end
  end

  def app_port
    proxy_config.fetch("app_port", 80)
  end

  def image
    proxy_config.fetch("image", DEFAULT_IMAGE)
  end

  def container_name
    "kamal-proxy"
  end

  def publish_args
    argumentize "--publish", [ "#{DEFAULT_HTTP_PORT}:#{DEFAULT_HTTP_PORT}", "#{DEFAULT_HTTPS_PORT}:#{DEFAULT_HTTPS_PORT}" ]
  end

  def ssl?
    proxy_config.fetch("ssl", false)
  end

  def deploy_options
    {
      host: proxy_config["host"],
      tls: proxy_config["ssl"],
      "deploy-timeout": proxy_config["deploy_timeout"],
      "drain-timeout": proxy_config["drain_timeout"],
      "health-check-interval": proxy_config.dig("health_check", "interval"),
      "health-check-timeout": proxy_config.dig("health_check", "timeout"),
      "health-check-path": proxy_config.dig("health_check", "path"),
      "target-timeout": proxy_config["response_timeout"],
      "buffer-requests": proxy_config.fetch("buffering", { "requests": true }).fetch("requests", true),
      "buffer-responses": proxy_config.fetch("buffering", { "responses": true }).fetch("responses", true),
      "buffer-memory": proxy_config.dig("buffering", "memory"),
      "max-request-body": proxy_config.dig("buffering", "max_request_body"),
      "max-response-body": proxy_config.dig("buffering", "max_response_body"),
      "forward-headers": proxy_config.dig("forward_headers"),
      "log-request-header": proxy_config.dig("logging", "request_headers") || DEFAULT_LOG_REQUEST_HEADERS,
      "log-response-header": proxy_config.dig("logging", "response_headers")
    }.compact
  end

  def deploy_command_args
    optionize deploy_options
  end

  private
    attr_accessor :proxy_config
end

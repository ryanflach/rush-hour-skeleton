require 'json'
require 'useragent'

module DataProcessor
  def parse_it(request)
    JSON.parse("#{request}")
  end

  def parse_and_format(request)
    parsed = parse_it(request)
    assign_data(parsed)
  end

  def process_foreign_tables(request)
    formatted = parse_and_format(request)
    url = assign_data_to_url(formatted)
    refer = assign_data_to_referred_by(formatted)
    type = assign_data_to_request_type(formatted)
    agent = assign_data_to_user_agent(formatted)
    res = assign_data_to_resolution(formatted)
    ip = assign_data_to_ip(formatted)
    {:requested_at => formatted[:requested_at], :responded_in => formatted[:responded_in],
    :url => url, :request_type => type, :resolution => res, :ip => ip,
    :u_agent => agent, :referred_by => refer}
  end

  def foreign_table_ids(request)
    data = process_foreign_tables(request)
    {:requested_at => data[:requested_at],
    :responded_in => data[:responded_in],
    :url_id => data[:url].id,
    :referred_by_id => data[:referred_by].id,
    :request_type_id => data[:request_type].id,
    :u_agent_id => data[:u_agent].id,
    :resolution_id => data[:resolution].id,
    :ip_id => data[:ip].id
    }
  end

  def process_payload(request)
    data = process_foreign_tables(request)
    PayloadRequest.find_or_create_by(data)
  end

  def valid_columns
    {"url" => :url, "requestedAt" => :requested_at,
     "respondedIn" => :responded_in, "referredBy" => :referred_by,
     "requestType" => :request_type, "userAgent" => :user_agent,
     "resolutionWidth" => :resolution_width,
     "resolutionHeight" => :resolution_height, "ip" => :ip}
  end

  def assign_data(data)
    data.map do |key, value|
      [valid_columns[key], value]
    end.to_h
  end

  def assign_url_data(data, type)
    url = data[type]
    split_url = url.split('/')
    if split_url.last.include?('.')
      root, path = split_url.join('/'), '/'
    else
      root, path = split_url[0...split_url.count-1].join('/'), "/#{split_url.last}"
    end
    {:root => root, :path => path}
  end

  def assign_data_to_url(data)
    url_data = assign_url_data(data, :url)
    Url.find_or_create_by(root_url: url_data[:root], path: url_data[:path])
  end

  def assign_data_to_referred_by(data)
    url_data = assign_url_data(data, :referred_by)
    ReferredBy.find_or_create_by(root_url: url_data[:root], path: url_data[:path])
  end

  def assign_data_to_request_type(data)
    RequestType.find_or_create_by(name: data[:request_type])
  end

  def assign_data_to_user_agent(data)
    agent = UserAgent.parse(data[:user_agent])
    UAgent.find_or_create_by(browser: agent.browser, operating_system: agent.os)
  end

  def assign_data_to_resolution(data)
    Resolution.find_or_create_by(width: data[:resolution_width], height: data[:resolution_height])
  end

  def assign_data_to_ip(data)
    Ip.find_or_create_by(address: data[:ip])
  end

  def clean_client_data(data)
    {identifier: data[:identifier], root_url: data[:rootUrl]}
  end
end

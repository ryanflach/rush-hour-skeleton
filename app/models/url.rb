class Url < ActiveRecord::Base
  has_many :payload_requests

  validates :root_url, presence: true
  validates :path, presence: true

  def self.all_paths
    Url.pluck(:path).uniq
  end

  def self.all_roots
    Url.pluck(:root_url).uniq
  end

  def self.most_to_least
    grouped = Url.group([:root_url] + [:path]).count

    array = grouped.sort_by do |key, value|
      value
    end.reverse


    array.map do |url, number|
      url.join
    end
  end

  def self.assemble_url(id)
    url = find(id)
    url.root_url + url.path
  end

  def self.response_times(id)
    url = find(id)
    url.payload_requests.pluck(:responded_in).sort.reverse
  end

  def self.verbs_used(id)
    requests = PayloadRequest.select(:request_type_id).where("url_id" == id)
    verb_ids = requests.pluck(:request_type_id).uniq

    verb_ids.map do |number|
      RequestType.find(number).name
    end
  end

  def self.top_referrers(id)
    referrers = PayloadRequest.select(:referred_by_id).where("url_id" == id)
    referrer_ids = referrers.pluck(:referred_by_id)

    id_hash = referrer_ids.group_by {|number| number}

    id_array = id_hash.values.sort_by {|value| value.count}

    id_array.reverse.flatten.uniq.map do |id_number|
      ReferredBy.find(id_number).root_url + ReferredBy.find(id_number).path
    end
  end

  def top_user_agents
    agents = PayloadRequest.select(:u_agent_id).where("u_agent_id" == self.id)
    # require "pry" ; binding.pry
    agent_ids = agents.pluck(:u_agent_id)

    id_hash = agent_ids.group_by {|number| number}

    id_array = id_hash.values.sort_by {|value| value.count}

    id_array.reverse.flatten.uniq.map do |id_number|
      "#{UAgent.find(id_number).browser}; " + "#{UAgent.find(id_number).operating_system}"
    end
  end
end

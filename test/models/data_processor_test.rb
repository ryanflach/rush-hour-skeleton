require_relative '../test_helper.rb'

class DataProcessorTest < Minitest::Test
  include DataProcessor, TestHelpers

  def test_it_can_appropriately_label_data_for_columns
    data = parse_it(raw_data)
    formatted = assign_data(data)
    assert_equal 37, formatted[:responded_in]
  end

  def test_it_can_assign_url_data
    formatted = parse_and_format(raw_data)
    assign_data_to_url(formatted)
    assert_equal "http://jumpstartlab.com", Url.first.root_url
    assert_equal "/blog", Url.first.path
  end

  def test_it_can_assign_referred_by_data
    formatted = parse_and_format(raw_data)
    assign_data_to_referred_by(formatted)
    assert_equal "http://jumpstartlab.com", ReferredBy.first.root_url
    assert_equal "/", ReferredBy.first.path
  end

  def test_it_can_assign_user_agent_data
    formatted = parse_and_format(raw_data)
    assign_data_to_user_agent(formatted)
    assert_equal "Chrome", UAgent.first.browser
    assert_equal "OS X 10.8.2", UAgent.first.operating_system
  end

  def test_it_can_assign_resolution_data
    formatted = parse_and_format(raw_data)
    assign_data_to_resolution(formatted)
    assert_equal 1920, Resolution.first.width
    assert_equal 1280, Resolution.first.height
  end

  def test_it_can_assign_ip_data
    formatted = parse_and_format(raw_data)
    assign_data_to_ip(formatted)
    assert_equal "63.29.38.211", Ip.first.address
  end

  def test_it_can_store_all_data_from_a_payload
    loaded = process_payload(raw_data)
    assert loaded.requested_at
    assert_equal 37, loaded.responded_in
    assert_equal 1, loaded.url_id
    assert_equal 1, loaded.request_type_id
    assert_equal 1, loaded.resolution_id
    assert_equal 1, loaded.ip_id
    assert_equal 1, loaded.u_agent_id
    assert_equal 1, loaded.referred_by_id
  end

  def test_it_does_not_store_duplicate_entires_within_foreign_key_tables
    process_payload(data_1)
    process_payload(data_8)
    assert_equal 2, PayloadRequest.count
    assert_equal 1, Url.all.count
    assert_equal 2, RequestType.all.count
    assert_equal 1, Resolution.all.count
    assert_equal 1, Ip.all.count
    assert_equal 1, UAgent.all.count
    assert_equal 1, ReferredBy.all.count
  end

  def test_it_can_handle_rootURl_key_from_client
    data = {'identifier': 'jumpstartlab', 'rootUrl': 'http://jumpstartlab.com'}
    cleaned = clean_client_data(data)
    client = Client.create(cleaned)
    assert_equal 1, Client.count
    assert_equal 'jumpstartlab', client.identifier
    assert_equal 'http://jumpstartlab.com', client.root_url
  end
end

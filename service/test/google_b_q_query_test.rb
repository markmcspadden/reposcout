require 'minitest/autorun'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib', 'google_b_q_query'))

class GoogleBQQueryTest < MiniTest::Unit::TestCase
  
  def setup
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response.json'))

    @bq = GoogleBQQuery.new

    @json = JSON.parse(@data)
  end

  def test_data_normalized_to_events
    events = @bq.data_normalized_to_events(@data)

    assert_equal @json["totalRows"].to_i, events.size
    assert_equal OpenStruct, events.sample.class
  end

  def test_attrs_from_json
    attrs = @bq.attrs_from_json(@json)

    assert_equal @json["totalRows"].to_i, attrs.size
    assert_equal 17, attrs.sample.keys.count
    assert_equal 6, attrs.last.values.compact.size
  end

  def test_fields_from_json
    fields = @bq.fields_from_json(@json)

    assert_equal 17, fields.count

    # Spot check
    assert_equal true, fields.include?("repository_watchers")
    assert_equal true, fields.include?("type")
    assert_equal true, fields.include?("payload_pull_request_merged_at")
  end

  def test_attrs_from_json_row_with_fields
    fields = @bq.fields_from_json(@json)

    attrs = @bq.attrs_from_json_row_with_fields(@json["rows"].first, fields)

    expected = {"repository_created_at"=>"2008-04-11 02:19:47", "repository_forks"=>"8462", "repository_open_issues"=>"644", "repository_watchers"=>"22615", "type"=>"IssuesEvent", "created_at"=>"2014-07-27 04:14:42", "payload_pull_request_created_at"=>nil, "payload_pull_request_state"=>nil, "payload_pull_request_merged"=>nil, "payload_pull_request_merged_at"=>nil, "payload_pull_request_closed_at"=>nil, "payload_pull_request_comments"=>nil, "payload_pull_request_review_comments"=>nil, "payload_action"=>"opened", "payload_issue"=>"38832050", "payload_commit"=>nil, "payload_comment_created_at"=>nil}

    assert_equal expected, attrs
  end

  def test_response_with_no_rows
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response_no_rows.json'))
    @json = JSON.parse(@data)

    assert_equal Hash.new, @bq.attrs_from_json(@json)
  end

end

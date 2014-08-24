require 'minitest/autorun'
require 'mocha/setup'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib', 'health'))

class HealthTest < MiniTest::Unit::TestCase

  
  # NOTE: events based on data in test/data/big_query_response_large.json
  # To test the time range features, I use a 5MB file of data
  # So it's beneficial to have my very own, hastily rolled #before_suite type functionality
  JSON_DATA = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response_large.json'))
  EVENTS = GoogleBQQuery.new.data_normalized_to_events(JSON_DATA)

  def setup
    @data = JSON_DATA

    @health = Health.new
    @health.events = EVENTS
    @health.end_time = DateTime.parse('2014-07-29 00:00:00').to_time.utc

    Time.stubs(:now).returns(DateTime.parse('2014-07-29 00:00:00').to_time.utc)
  end

  def test_events_in_time_range
    events = @health.events_in_time_range("2014-07-23 00:00:00", "2014-07-24 00:00:00")
    assert_equal 151, events.count
  end

  def test_watch_events
    assert_equal "WatchEvent", @health.watch_events.sample.type
    assert_equal @data.scan("WatchEvent").size, @health.watch_events.count
  end
  def test_fork_events
    assert_equal "ForkEvent", @health.fork_events.sample.type
    assert_equal @data.scan("ForkEvent").size, @health.fork_events.count
  end
  def test_issue_events
    sample = @health.issue_events.sample
    assert sample.type == "IssuesEvent" || 
            sample.type == "IssueCommentEvent"
    assert_equal @data.scan("IssuesEvent").size + @data.scan("IssueCommentEvent").size, @health.issue_events.count
  end
  def test_pull_request_events
    sample = @health.pull_request_events.sample
    assert sample.type == "PullRequestEvent" ||
            sample.type == "PullRequestReviewCommentEvent"
    assert_equal @data.scan("PullRequestEvent").size + @data.scan("PullRequestReviewCommentEvent").size, @health.pull_request_events.count
  end
  def test_push_events
    assert_equal "PushEvent", @health.push_events.sample.type
    assert_equal @data.scan("PushEvent").size, @health.push_events.count
  end

  def test_watch_health
    assert @health.watch_health.is_a?(WatchHealth)
    assert_equal @health.watch_events, @health.watch_health.events
  end
  def test_fork_health
    assert @health.fork_health.is_a?(ForkHealth)
    assert_equal @health.fork_events, @health.fork_health.events
  end
  def test_pull_request_health
    assert @health.pull_request_health.is_a?(PullRequestHealth)
    assert_equal @health.pull_request_events, @health.pull_request_health.events
  end
  # TODO: Test other healths

  def test_last_30_watch_events
    assert_equal "WatchEvent", @health.last_30_watch_events.sample.type
    assert_equal 457, @health.last_30_watch_events.count
  end
  def test_last_30_watch_health
    assert @health.last_30_watch_health.is_a?(WatchHealth)
    assert_equal @health.last_30_watch_events, @health.last_30_watch_health.events
  end
  # TODO: Test other last_30s

  # TODO: Test other last_XXs

  def test_last_30_score
    assert_equal 1.0, @health.last_30_score
  end
  # TODO: Test last_XX_score

  def test_score_in_words
    assert_equal "Great", @health.score_in_words
  end

end

class MetaHealthTest < MiniTest::Unit::TestCase

  def test_presence
    assert MetaHealth
  end

end

class WatchHealthTest < MiniTest::Unit::TestCase
  def setup
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response.json'))
    
    @health = Health.new
    @health.events = GoogleBQQuery.new.data_normalized_to_events(@data)

    @watch_health = WatchHealth.new(:events => @health.watch_events)
  end

  def test_score
    expected = @data.scan("started").size/@data.scan("WatchEvent").size.to_f
    assert_equal expected, @watch_health.score
  end

  def test_score_with_no_events
    @watch_health.events = []
    assert_equal 0.0, @watch_health.score
  end

  def test_count
    assert_equal @data.scan("WatchEvent").size, @watch_health.count
  end
end

class ForkHealthTest < MiniTest::Unit::TestCase
  def setup
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response.json'))
    
    @health = Health.new
    @health.events = GoogleBQQuery.new.data_normalized_to_events(@data)

    @fork_health = ForkHealth.new(:events => @health.fork_events)
  end

  def test_score
    assert_equal 1.0, @fork_health.score
  end
  # TODO: Test all score steps

  def test_count
    assert_equal @data.scan("ForkEvent").size, @fork_health.count
  end
end

class IssueHealthTest < MiniTest::Unit::TestCase
  def setup
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response_thoughtbot_paperclip.json'))
    
    @health = Health.new
    @health.events = GoogleBQQuery.new.data_normalized_to_events(@data)

    @issue_health = IssueHealth.new(:events => @health.issue_events)
  end

  def test_score
    assert_equal 1.0, @issue_health.score
  end
  def test_score_with_no_events
    @issue_health.events = []
    assert_equal 0.0, @issue_health.score
  end
  def test_score_on_last_30
    @issue_health.events = @health.last_30_issue_events
    assert @issue_health.score < 0.6 && @issue_health.score > 0.5
  end
  # TODO: Test all score steps

  def test_count
    assert_equal @data.scan("IssuesEvent").size + @data.scan("IssueCommentEvent").size, @issue_health.count
  end
end

class PullRequestHealthTest < MiniTest::Unit::TestCase
  def setup
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response.json'))
    
    @health = Health.new
    @health.events = GoogleBQQuery.new.data_normalized_to_events(@data)

    @pull_request_health = PullRequestHealth.new(:events => @health.pull_request_events)
  end

  def test_score
    assert_equal 1.0, @pull_request_health.score
  end
  def test_score_with_no_events
    @pull_request_health.events = []
    assert_equal 0.0, @pull_request_health.score
  end
  # TODO: Test all score steps

  def test_count
    assert_equal @data.scan("PullRequestEvent").size + @data.scan("PullRequestReviewCommentEvent").size, @pull_request_health.count
  end
end

class PushHealthTest < MiniTest::Unit::TestCase
  def setup
    @data = File.read(File.join(File.dirname(__FILE__), 'data', 'big_query_response.json'))
    
    @health = Health.new
    @health.events = GoogleBQQuery.new.data_normalized_to_events(@data)

    @push_health = PushHealth.new(:events => @health.push_events)
  end

  def test_score
    assert_equal 1.0, @push_health.score
  end
  # TODO: Test all score steps

  def test_count
    assert_equal @data.scan("PushEvent").size, @push_health.count
  end
end

require 'pp'
require 'json'

# TODO: Only require the active_support being used
# Using: 
#   Array#sum
#   Time#beginning_of_day
#   String#classify and String#constantize
require 'active_support/all'

require File.expand_path(File.join(File.dirname(__FILE__), 'health_reading'))
require File.expand_path(File.join(File.dirname(__FILE__), 'google_b_q_query'))

class AbstractHealth
  attr_accessor :events, :score, :count, :start_time, :end_time

  def initialize(attrs={})
    super()

    if attrs[:events]
      @events = attrs[:events]
    end

    @end_time ||= Time.now.utc.beginning_of_day
  end

  # NOTE: Inclusive on the start date, exclusive on the end date
  # NOTE: Params can be a String or Time. That's not confusing at all.
  def events_in_time_range(start_date_string, end_date_string)
    return self.events if self.events.nil?

    if(start_date_string.is_a?(String))
      # I was told there would be no timezones :/
      start_time =  DateTime.parse(start_date_string).to_time.utc
      end_time = DateTime.parse(end_date_string).to_time.utc
    else
      start_time = start_date_string
      end_time = end_date_string
    end

    self.events.select do |e| 
      created_at_time = DateTime.parse(e.created_at).to_time.utc
      created_at_time >= start_time && created_at_time < end_time
    end
  end
end

class Health < AbstractHealth
  attr_accessor :healths
  attr_accessor :meta_events, :watch_events, :fork_events, :issue_events, :pull_request_events, :push_events

  SUB_HEALTHS = %w(meta watch fork issue pull_request push)

  def initialize(attrs={})
    super

    @healths ||= []
  end

  def events_query_string(owner_name, repo_name, start_date_string, end_date_string)
    # query_string = "SELECT type, count(type) as events, repository_description, repository_url FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type, repository_description, repository_url ORDER BY events DESC"
    # query_string = "SELECT type, count(type) as events FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type ORDER BY events DESC"
    query_string = <<-EOS
      SELECT repository_created_at, repository_forks, repository_open_issues, repository_watchers, type, created_at, 
        payload_pull_request_created_at, payload_pull_request_state,
        payload_pull_request_merged, payload_pull_request_merged_at, payload_pull_request_closed_at, 
        payload_pull_request_comments, payload_pull_request_review_comments,
        payload_action, payload_issue, payload_commit,
        payload_comment_created_at
      FROM [githubarchive:github.timeline] 
      WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' 
        AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') 
        AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') 
    EOS
  end

  def fetch_query(query_string)
    GoogleBQQuery.new.query(query_string)
  end

  # TODO: Cache this or stop calling it so dang much
  def events_from_big_query_for_repo_in_date_range(owner_name, repo_name, start_date_string, end_date_string)
    return @events if @events

    query_string = events_query_string(owner_name, repo_name, start_date_string, end_date_string)

    json = fetch_query(query_string)
    @events = json

    # clear_event_memoizations
  end

  def meta_events
    @meta_events ||= events
  end
  def watch_events
    @watch_events ||= events.select{ |e| e.type == "WatchEvent" }
  end
  def fork_events
    @fork_events ||= events.select{ |e| e.type == "ForkEvent" }
  end
  def issue_events
    @issue_events ||= events.select{ |e| e.type[/IssuesEvent|IssueCommentEvent/] }
  end
  def pull_request_events
    @pull_request_events ||= events.select{ |e| e.type[/PullRequestEvent|PullRequestReviewCommentEvent/] }
  end
  def push_events
    @push_events ||= events.select{ |e| e.type == "PushEvent" }
  end

  # OMG I REMEMBER HOW TO META PROGRAM. (I'M SORRY.)
  # Create *type*_health methods
  # def watch_health
  #   @watch_health ||= WatchHealth.new(:events => watch_events)
  # end
  #
  # OK. It's actually implemented more like...
  #
  # def watch_health
  #   return @watch_health if @watch_health
  #   @watch_health = WatchHealth.new(:events => watch_events)
  # end
  # 
  SUB_HEALTHS.each do |type|
    define_method("#{type}_health".to_sym) do
      return self.instance_variable_get("@" + "#{type}_health") if self.instance_variable_get("@" + "#{type}_health")
      self.instance_variable_set("@" + "#{type}_health", "#{type}_health".classify.constantize.new(:events => self.send("#{type}_events".to_sym)))
    end
  end

  # UH OH. Remembered how to do that meta programming thing again.
  # Even added double nesting.
  # Pray you don't see another block like this. Who knows what it might contain.
  #
  # def last_7_watch_events
  #   @last_7_watch_events ||= Health.new(:events => events_in_time_range(self.end_time.advance(:days => -1*days),self.end_time)).watch_events
  # end
  # def last_7_watch_health
  #   @last_7_watch_health ||= WatchHealth.new(:events => last_7_watch_events)
  # end
  # def last_30_watch_events
  #   @last_30_watch_events ||= events_in_time_range
  # end
  # def last_30_watch_health
  #   @last_30_watch_health ||= WatchHealth.new(:events => last_30_watch_events)
  # end
  [7, 30].each do |days|
    SUB_HEALTHS.each do |type|
      define_method("last_#{days}_#{type}_events".to_sym) do
        return self.instance_variable_get("@" + "last_#{days}_#{type}_events") if self.instance_variable_get("@" + "last_#{days}_#{type}_events")
        self.instance_variable_set("@" + "last_#{days}_#{type}_events", Health.new(:events => events_in_time_range(self.end_time.advance(:days => -1*days),self.end_time)).send("#{type}_events".to_sym))
      end
      define_method("last_#{days}_#{type}_health".to_sym) do
        return self.instance_variable_get("@" + "last_#{days}_#{type}_health") if self.instance_variable_get("@" + "last_#{days}_#{type}_health")
        self.instance_variable_set("@" + "last_#{days}_#{type}_health", "#{type}_health".classify.constantize.new(:events => self.send("last_#{days}_#{type}_events".to_sym)))
      end
    end
  end

  # Just once more.
  # I can quit anytime.
  # def last_7_score
  #   scores = watch_health.score + ... + push_health.score
  #   scores.sum/scores.size.to_f
  # end
  [7, 30].each do |days|
    define_method("last_#{days}_score".to_sym) do
      scores = SUB_HEALTHS.map do |type|
                  self.send("last_#{days}_#{type}_health".to_sym).score # Scary
               end
      scores.sum/scores.size.to_f
    end
  end

  def score
    #(last_7_score + last_30_score)/2.0
    last_30_score
  end

  def count
    self.events.count
  end


  # Scores are 0 to 1
  def score_in_words
    case score*10
      when 0..4 
        "Sad"
      when 4..7
        "Meh"
      when 7..9
        "Good"
      when 9..10
        "Great"
      else "Unknown"
    end
  end

  def score_base_100_from_score(score)
    (score*100).round
  end

  def score_phrase
    score_phrase_from_words(score_in_words)
  end

  def score_phrase_from_words(words)
    case words
      when "Great"
        "Top Repo. Can't go wrong here."
      when "Good"
        "All Clear. Use at will."
      when "Meh"
        "Low Activity. Use with caution."
      when "Sad"
        "Danger. Extremely low activity levels."
      else
        "Low Visibility. Status unclear."
    end
  end

  def health_json_from_repo(repo)
    # TODO: Detect if there is one cached recently or go get another one
    cached_health = HealthReading.dataset.where(:repo => repo).order(:id).last

    # TODO: Probably need to background this
    if(!cached_health)
      cache_health_reading_from_repo(repo)
      cached_health = HealthReading.dataset.where(:repo => repo).order(:id).last              
    end

    cached_health_attributes = cached_health[:health_attributes]

    last_7 = {
                :watch_score => cached_health_attributes[:last_7_watch_score],
                :fork_score => cached_health_attributes[:last_7_fork_score],
                :issue_score => cached_health_attributes[:last_7_issue_score],
                :pr_score => cached_health_attributes[:last_7_pr_score],
                :push_score => cached_health_attributes[:last_7_push_score],
                :watch_counts => cached_health_attributes[:last_7_watch_counts],
                :fork_counts => cached_health_attributes[:last_7_fork_counts],
                :issue_counts => cached_health_attributes[:last_7_issue_counts],
                :pr_counts => cached_health_attributes[:last_7_pr_counts],
                :push_counts => cached_health_attributes[:last_7_push_counts]
              }
    last_30 = {
          :watch_score => cached_health_attributes[:last_30_watch_score],
          :fork_score => cached_health_attributes[:last_30_fork_score],
          :issue_score => cached_health_attributes[:last_30_issue_score],
          :pr_score => cached_health_attributes[:last_30_pr_score],
          :push_score => cached_health_attributes[:last_30_push_score],
          :watch_counts => cached_health_attributes[:last_30_watch_counts],
          :fork_counts => cached_health_attributes[:last_30_fork_counts],
          :issue_counts => cached_health_attributes[:last_30_issue_counts],
          :pr_counts => cached_health_attributes[:last_30_pr_counts],
          :push_counts => cached_health_attributes[:last_30_push_counts]
        }
    {
      "overall_health" => cached_health[:overall_health],
      "overall_health_score_100" => score_base_100_from_score(cached_health[:overall_health_score]),
      "overall_health_phrase" => score_phrase_from_words(cached_health[:overall_health]),
      "last_7" => last_7,
      "last_30" => last_30
    }
  end

  def cache_health_reading_from_repo(repo)
    owner_name, repo_name = repo.split("/")

    self.events = events_from_big_query_for_repo_in_date_range(owner_name, repo_name, "2013-08-01 00:00:00", "2014-08-12 00:00:00")

    puts self.events.count

    attributes = {
      "repo" => repo,
      "overall_health" => score_in_words,
      "overall_health_score" => score
    }

    health_attributes = {
      "meta_health" => meta_health.score,
      "last_7_watch_score" => last_7_watch_health.score,
      "last_7_fork_score" => last_7_fork_health.score,
      "last_7_issue_score" => last_7_issue_health.score,
      "last_7_pr_score" => last_7_pull_request_health.score,
      "last_7_push_score" => last_7_push_health.score,
      "last_7_watch_counts" => last_7_watch_health.count,
      "last_7_fork_counts" => last_7_fork_health.count,
      "last_7_issue_counts" => last_7_issue_health.count,
      "last_7_pr_counts" => last_7_pull_request_health.count,
      "last_7_push_counts" => last_7_push_health.count,
      "last_30_watch_score" => last_30_watch_health.score,
      "last_30_fork_score" => last_30_fork_health.score,
      "last_30_issue_score" => last_30_issue_health.score,
      "last_30_pr_score" => last_30_pull_request_health.score,
      "last_30_push_score" => last_30_push_health.score,
      "last_30_watch_counts" => last_30_watch_health.count,
      "last_30_fork_counts" => last_30_fork_health.count,
      "last_30_issue_counts" => last_30_issue_health.count,
      "last_30_pr_counts" => last_30_pull_request_health.count,
      "last_30_push_counts" => last_30_push_health.count,
    }

    attributes[:health_attributes] = Sequel.hstore(health_attributes)

    puts attributes

    HealthReading.dataset.insert(attributes)
  end



end


# FIX: I've left out Meta from many of the methods :(

# Repo been around longer than 6 months?
# Total number of watchers > 100?
class MetaHealth < AbstractHealth

  def score
    old = events.first.repository_created_at.to_time < Time.now.advance(:months => -6)
    if(old)
      1.0
    else
      0.5 # Lazy
    end
  end

  def count
    1
  end
end

# Ratio of added to removed watches
# Data Question: How many unwatches are their?
class WatchHealth < AbstractHealth

  def score
    started = events.select{ |e| e.payload_action == "started" }

    started.count/events.count.to_f
  rescue
    0.0
  end

  def count
    events.count
  end
end

# Ratio of forks to ???
# Should be based off of total forks???
# Data Question: What's the average number of forks per repo
# Data Question: What's the average number of forks per repo in a week
# Data Question: What's the average number of forks per repo in a month
class ForkHealth < AbstractHealth
  def score
    case events.count
      when 0
        0.0
      when 1..5
        0.25
      when 5..15
        0.5
      when 15..30
        0.75
      else
        1.0
    end
  rescue
    0.0
  end

  def count
    events.count
  end
end

# Let's make this complicated:
#   You get 4 points for a closed issue
#   You get -1 points for an open issue
#   You get 0.2 points for an issue comment
#   Finally you normalize against the total number of total and newly opened issue events
#   Or at least that's the idea anyways
# Data Question: Comments to Close Ratio?
class IssueHealth < AbstractHealth
  def score    
    issue_events = events.select{ |e| !e.payload_action.nil? }
    opened = issue_events.select{ |e| e.payload_action == "opened" }
    closed = issue_events.select{ |e| e.payload_action == "closed" }

    comment_events = events.select{ |e| e.payload_action.blank? }

    oc_score = (closed.size*4 - opened.size)/issue_events.size.to_f
    com_score = comment_events.count*0.2/opened.size.to_f

    # Dividing by 0.0 leads to infinity, which is not fun for addition
    raw_score = 0.0
    raw_score += oc_score if oc_score < Float::INFINITY
    raw_score += com_score if com_score < Float::INFINITY

    if raw_score < 0
      0.0
    elsif raw_score > 1
      1.0
    else
      raw_score
    end
  rescue
    0.0
  end

  def count
    events.count
  end
end


# After that last one, I just don't even know what to expect here
# Data Question: Number of sad_closed v. merged
class PullRequestHealth < AbstractHealth
  def score
    prs = events.select{ |e| e.type == "PullRequestEvent" }
    opened = prs.select{ |e| e.payload_action == "opened"}
    
    all_closed = prs.select{ |e| e.payload_action == "closed"}
    
    merged = all_closed.select{ |e| !e.payload_pull_request_merged_at.blank? }
    sad_closed = all_closed.select{ |e| e.payload_pull_request_merged_at.blank? }

    comments = events.select{ |e| e.type == "PullRequestEvent" }

    p_score = (merged.size*4 + sad_closed.size - opened.size)/prs.size.to_f
    c_score = (comments.size*0.2)/opened.size.to_f

    puts p_score
    puts c_score

    # Dividing by 0.0 leads to infinity, which is not fun for addition
    raw_score = 0.0
    raw_score += p_score if p_score < Float::INFINITY
    raw_score += c_score if c_score < Float::INFINITY

    if raw_score < 0.0
      0.0
    elsif raw_score > 1.0
      1.0
    else
      raw_score
    end
  rescue
    0.0
  end

  def count
    events.count
  end
end

# Ratio? commits v total commit?
# Data Question: ?
class PushHealth < AbstractHealth
  def score
    case count
      when 0
        0.0
      when 1..5
        0.25
      when 5..15
        0.5
      when 15..30
        0.75
      else
        1.0
    end
  rescue
    0.0
  end

  def count
    events.count
  end
end


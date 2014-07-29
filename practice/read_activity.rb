require 'open-uri'
require 'zlib'
require 'yajl'
require 'pp'

require 'rubygems'
require 'active_support/all'

@events = []


def read_jsons 
  (0..14).each do |i|
    puts "Reading 2014-05-05-#{i}"
    gz = open("data/2014-05-05-#{i}.json.gz")
    js = Zlib::GzipReader.new(gz).read

    Yajl::Parser.parse(js) do |event|
      @events << event
    end
  end
end

def find_repo_by_owner_and_name(owner_name, repo_name)
  @events.collect do |event|
    event["repository"] &&
    event["repository"]["name"] == repo_name && 
    event["repository"]["owner"] == owner_name
  end
end

def events_by_repo_id(repo_id)
  @events.select do |event|
    event["repository"] &&
    event["repository"]["id"] == repo_id
  end
end

def overall_score_for_events(events)
  scores = [ watch_score_for_events(events),
             fork_score_for_events(events),
             issue_score_for_events(events),
             pr_score_for_events(events),
             push_score_for_events(events) ]
  scores.sum/scores.count.to_f 
end

# If there's a watch, that's good.
# If not, that's bad
def watch_score_for_events(events)
  score = 0
  if events.detect{ |e| e["type"] == "WatchEvent" }
    score = 1
  end
  score
end

def fork_score_for_events(events)
  score = 0
  if events.detect{ |e| e["type"] == "ForkEvent" }
    score = 1
  end
  score
end

def issue_score_for_events(events)
  score = 0
  if events.detect{ |e| e["type"] == "IssuesEvent" || e["type"] == "IssueCommentEvent" }
    score = 1
  end
  score
end

def pr_score_for_events(events)
  score = 0
  if events.detect{ |e| e["type"] == "PullRequestEvent" || e["type"] == "PullRequestReviewCommentEvent" }
    score = 1
  end
  score
end

def push_score_for_events(events)
  score = 0
  if events.detect{ |e| e["type"] == "PushEvent" }
    score = 1
  end
  score
end

# find_repo_by_owner_and_name("rails", "rails")
def test_rails
  read_jsons
  
  rails_events = events_by_repo_id(8514) #rails

  pp rails_events.count.to_s + " Events"
  pp rails_events.map{ |e| e["type"] }
  pp rails_events.group_by{ |e| e["type"] }.map{ |type, events| [type, events.count] }
end

def test_ids(ids)
  read_jsons

  ids.each do |id, name|
    events = events_by_repo_id(id)
    pp events.first["repository"]["name"]
    pp events.count.to_s + " Events"
    pp events.group_by{ |e| e["type"] }.map{ |type, events| [type, events.count] } 
    pp overall_score_for_events(events)
  end
end

def test_all
  read_jsons

  ids = @events.select{ |e| e["repository"] }.map{ |e| [e["repository"]["id"],e["repository"]["owner"] + "/" + e["repository"]["name"]] }.uniq
  ids.each do |id, name|
    events = events_by_repo_id(id)
    pp name + " - #{id}"
    pp events.count.to_s + " Events"
    pp events.group_by{ |e| e["type"] }.map{ |type, events| [type, events.count] } 
    pp overall_score_for_events(events)
  end
end

def test_all_sorted
  read_jsons

  ids = @events.select{ |e| e["repository"] }.map{ |e| [e["repository"]["id"],e["repository"]["owner"] + "/" + e["repository"]["name"]] }.uniq
  ids.sort_by{ |i| overall_score_for_events(events_by_repo_id(i)) }
  ids.reverse[0..99].each do |id, name|
    events = events_by_repo_id(id)
    pp name + " - #{id}"
    pp events.count.to_s + " Events"
    pp events.group_by{ |e| e["type"] }.map{ |type, events| [type, events.count] } 
    pp overall_score_for_events(events)
  end
end

# test_ids([8514, 19307838, 13262813])
#test_all
test_all_sorted



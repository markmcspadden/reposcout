require 'pp'
require 'json'

# Only using Array#sum currently
require 'active_support/all'

$project_id = "jovial-opus-656"


def events_from_big_query_for_repo_in_date_range(owner_name, repo_name, start_date_string, end_date_string)
  # query_string = "SELECT type, count(type) as events, repository_description, repository_url FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type, repository_description, repository_url ORDER BY events DESC"
  query_string = "SELECT type, count(type) as events FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type ORDER BY events DESC"

  output = `bq --project_id #{$project_id} --format json query "#{query_string}"`

  json_string = output.strip.split("\n").last

  json = JSON.parse(json_string)

  pp json

  json
end

def overall_score_from_json(json)
  types = json.map{ |j| j["type"] }.uniq

  watch_score = types.include?("WatchEvent") ? 1 : 0
  fork_score = types.include?("ForkEvent") ? 1 : 0
  issue_score = types.include?("IssuesEvent") || types.include?("IssueCommentEvent") ? 1 : 0
  pr_score = types.include?("PullRequestEvent") || types.include?("PullRequestReviewCommentEvent") ? 1 : 0
  push_score = types.include?("PushEvent") ? 1 : 0

  scores = [ watch_score,
             fork_score,
             issue_score,
             pr_score,
             push_score ]

  scores.sum/scores.count.to_f
end

def cumulative_score_for_repo(repo)
  owner_name, repo_name = repo.to_s.split("/")

  last_week_json = events_from_big_query_for_repo_in_date_range(owner_name, repo_name, "2014-07-22 00:00:00", "2014-07-29 00:00:00")
  last_week_score = overall_score_from_json(last_week_json)

  last_month_json = events_from_big_query_for_repo_in_date_range(owner_name, repo_name, "2014-06-29 00:00:00", "2014-07-29 00:00:00")
  last_month_score = overall_score_from_json(last_month_json)

  cumulative_score = (last_week_score + last_month_score)/2.0
end

# Scores are 0 to 1
def health_from_cumulative_score(score)
  case score*10
    when 0..4 
      "Sad"
    when 4..7
      "Meh"
    when 7..9
      "Good"
    else "Great"
  end
end

def test_all
  %w(rails/rails 
      technoweenie/attachment_fu 
      thoughtbot/paperclip 
      carrierwaveuploader/carrierwave).each do |repo|

    score = cumulative_score_for_repo(repo)

    pp "#{repo}: #{score} - #{health_from_cumulative_score(score)}"
  end
end

test_all


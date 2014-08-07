require 'pp'
require 'json'

# Only using Array#sum currently
require 'active_support/all'

require File.expand_path(File.join(File.dirname(__FILE__), 'google_b_q_query'))

class Health
  $project_id = "jovial-opus-656"

  class << self

    # TODO: Cache this or stop calling it so dang much
    def events_from_big_query_for_repo_in_date_range(owner_name, repo_name, start_date_string, end_date_string)
      # query_string = "SELECT type, count(type) as events, repository_description, repository_url FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type, repository_description, repository_url ORDER BY events DESC"
      query_string = "SELECT type, count(type) as events FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type ORDER BY events DESC"

      json = fetch_query(query_string)
    end

    def overall_score_from_json(json)
      # types = json.map{ |j| j["type"] }.uniq
      types = json_to_collection(json)

      scores = [ watch_score_from_collection(types),
                 fork_score_from_collection(types),
                 issue_score_from_collection(types),
                 pr_score_from_collection(types),
                 push_score_from_collection(types) ]

      scores.sum/scores.count.to_f
    end

    def json_to_collection(json)
      json.map{ |j| j.first }.uniq
    end

    def watch_score_from_collection(collection)
      collection.include?("WatchEvent") ? 1 : 0
    end

    def fork_score_from_collection(collection)
      collection.include?("ForkEvent") ? 1 : 0
    end

    def issue_score_from_collection(collection)
      collection.include?("IssuesEvent") || collection.include?("IssueCommentEvent") ? 1 : 0
    end

    def pr_score_from_collection(collection)
      collection.include?("PullRequestEvent") || collection.include?("PullRequestReviewCommentEvent") ? 1 : 0
    end

    def push_score_from_collection(collection)
      collection.include?("PushEvent") ? 1 : 0
    end

    def cumulative_score_for_repo(repo)
      last_week_score = overall_score_from_json(last_week_json(repo))
      last_month_score = overall_score_from_json(last_month_json(repo))

      cumulative_score = (last_week_score + last_month_score)/2.0
    end

    def last_week_json(repo)
      owner_name, repo_name = repo.to_s.split("/")
      last_week_json = events_from_big_query_for_repo_in_date_range(owner_name, repo_name, "2014-07-22 00:00:00", "2014-07-29 00:00:00")
    end

    def last_month_json(repo)
      owner_name, repo_name = repo.to_s.split("/")
      last_month_json = events_from_big_query_for_repo_in_date_range(owner_name, repo_name, "2014-06-29 00:00:00", "2014-07-29 00:00:00")
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

    def health_from_repo(repo)
      score = cumulative_score_for_repo(repo)
      health_from_cumulative_score(score)
    end



    def health_json_from_repo(repo)
      last_7 = {
                  "watch_score" => watch_score_from_collection(json_to_collection(last_week_json(repo))),
                  "fork_score" => fork_score_from_collection(json_to_collection(last_week_json(repo))),
                  "issue_score" => issue_score_from_collection(json_to_collection(last_week_json(repo))),
                  "pr_score" => pr_score_from_collection(json_to_collection(last_week_json(repo))),
                  "push_score" => push_score_from_collection(json_to_collection(last_week_json(repo))),
                }
      last_30 = {
            "watch_score" => watch_score_from_collection(json_to_collection(last_month_json(repo))),
            "fork_score" => fork_score_from_collection(json_to_collection(last_month_json(repo))),
            "issue_score" => issue_score_from_collection(json_to_collection(last_month_json(repo))),
            "pr_score" => pr_score_from_collection(json_to_collection(last_month_json(repo))),
            "push_score" => push_score_from_collection(json_to_collection(last_month_json(repo))),
          }
      {
        "overall_health" => health_from_repo(repo),
        "last_7" => last_7,
        "last_30" => last_30
      }
    end

    def fetch_query(query_string)
      GoogleBQQuery.new.query(query_string)
    end

    def old_fetch_query(query_string)
      output = `bq --project_id #{$project_id} --format json query "#{query_string}"`

      json_string = output.strip.split("\n").last

      json = JSON.parse(json_string)

      pp json

      json
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
  end

end

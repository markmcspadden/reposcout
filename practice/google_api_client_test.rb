
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

require 'json'
require 'pp'

# Initialize the client.
client = Google::APIClient.new(
  :application_name => 'Example Ruby application',
  :application_version => '1.0.0'
)

puts client

bq = client.discovered_api('bigquery','v2')

puts bq

# puts client

# puts File.expand_path(File.join(File.dirname(__FILE__), "../service/security", "GitHub Data Hack 3-78e77f54ba5a.p12"))
# key = Google::APIClient::KeyUtils.load_from_pkcs12(File.join(File.dirname(__FILE__), "../service/security", "GitHub Data Hack 3-78e77f54ba5a.p12"), 'notasecret')
# puts key


key_string = ENV["GOOGLE_API_PRIVATE_KEY"]
key = OpenSSL::PKey::RSA.new key_string, 'notasecret'

client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/bigquery',
  :issuer => ENV["GOOGLE_API_ISSUER"],
  :signing_key => key)
client.authorization.fetch_access_token!

owner_name = "rails"
repo_name = "rails"
start_date_string = "2014-07-22 00:00:00"
end_date_string = "2014-07-29 00:00:00"

query_string = "SELECT type, count(type) as events FROM [githubarchive:github.timeline] WHERE repository_owner='#{owner_name}' AND repository_name='#{repo_name}' AND PARSE_UTC_USEC(created_at) >= PARSE_UTC_USEC('#{start_date_string}') AND PARSE_UTC_USEC(created_at) <= PARSE_UTC_USEC('#{end_date_string}') GROUP BY type ORDER BY events DESC"



resp = client.execute(
    :api_method =>  bq.jobs.query,
    :body_object => { "query" => query_string },
    :parameters => { "projectId" => "jovial-opus-656",
                    "format" => "json" })

puts resp
puts resp.data

json = JSON.parse(resp.body)

pp json

pp json["rows"].map{ |r| r["f"] }.map{ |field, value| [field["v"], value["v"]] }

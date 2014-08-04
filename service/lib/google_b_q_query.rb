require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

class GoogleBQQuery

  def client
    @client ||= Google::APIClient.new(
      :application_name => 'Repo Health Application',
      :application_version => '0.0.1'
    )
  end

  def bq_api
    @bq_api ||= client.discovered_api('bigquery','v2')
  end

  def signed_key
    puts ENV["GOOGLE_API_PRIVATE_KEY"]
    @signed_key ||= OpenSSL::PKey::RSA.new ENV["GOOGLE_API_PRIVATE_KEY"], 'notasecret'
  end

  def auth
    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/bigquery',
      :issuer => ENV["GOOGLE_API_ISSUER"],
      :signing_key => signed_key)
    client.authorization.fetch_access_token!
  end

  # TODO: Rename or split out query/response
  def query(query)
    auth

    resp = client.execute(
              :api_method =>  bq_api.jobs.query,
              :body_object => { "query" => query },
              :parameters => { "projectId" => "jovial-opus-656",
                              "format" => "json" })

    puts resp
    puts resp.data
    puts resp.body

    json = JSON.parse(resp.body)
    json = json["rows"].map{ |r| r["f"] }.map{ |field, value| [field["v"], value["v"]] }
  end

end

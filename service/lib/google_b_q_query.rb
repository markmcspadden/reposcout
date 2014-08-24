require 'ostruct'
require 'json'

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

    puts query

    resp = client.execute(
              :api_method =>  bq_api.jobs.query,
              :body_object => { "query" => query },
              :parameters => { "projectId" => "jovial-opus-656",
                              "format" => "json" })

    data_normalized_to_events(resp.body)
  end

  # NOTE: Data requires that fields are kept in order
  # See test/data/big_query_response.json for an example
  def data_normalized_to_events(data)
    json = JSON.parse(data)

    fields = fields_from_json(json)

    events = attrs_from_json(json).map{ |a| OpenStruct.new(a) }
  end

  def fields_from_json(json)
    json["schema"]["fields"].map{ |f| f["name"] }
  end


  def attrs_from_json(json)
    fields = fields_from_json(json)

    return {} if !json["rows"]

    json["rows"].map do |row| 
      attrs_from_json_row_with_fields(row, fields)
    end
  end

  def attrs_from_json_row_with_fields(json_row, fields)
    attrs = {}
    json_row["f"].each_with_index{ |v, idx| attrs[fields[idx]] = v["v"] }
    attrs
  end

end

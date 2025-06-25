require "json/jwt"
require "httparty"
require "uri"

require_relative "line_item"
require_relative "score"
require_relative "result"
require_relative "../security/access_token"

module LtiBridge
  class AGS
    
    def initialize(access_token:)
      @access_token = access_token
    end

    def submit_score(score:, lineitem:)
      score_url = score_url(lineitem_id: lineitem.id)

      response = HTTParty.post(score_url,
        headers: {
          'Content-Type' => 'application/vnd.ims.lis.v1.score+json',
          'Authorization' => "Bearer #{@access_token}"
        },
        body: score.to_json
      )

      unless response.code.between?(200, 299)
        raise "Score submission failed: #{response.body}"
      end
    end

    def get_results(lineitem_id:, query: {})
      uri = results_url(lineitem_id: lineitem_id)

      response = HTTParty.get(uri, headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Accept' => 'application/vnd.ims.lis.v2.resultcontainer+json'
        },
        query: query
      )
      
      results = JSON.parse(response.body)
      results.map { |result_data| Result.new_from_api_response(result_data) }
    end

    def score_url(lineitem_id:)
      build_lineitem_sub_url(lineitem_id, "scores")
    end

    def results_url(lineitem_id:)
      build_lineitem_sub_url(lineitem_id, "results")
    end

    private

    def build_lineitem_sub_url(lineitem_id, suffix)
      uri = URI.parse(lineitem_id)
      query = uri.query
      uri.query = nil
      "#{uri}/#{suffix}#{query ? "?#{query}" : ''}"
    end

  end
end

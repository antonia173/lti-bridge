require "json/jwt"
require "httparty"
require "uri"

require_relative "line_item"
require_relative "score"
require_relative "result"
require_relative "logger"

module LtiBridge
  class AGS
    
    def initialize(access_token:)
      @access_token = access_token
    end

   # Line Item Service
       
    def find_or_create_line_item(lineitems_url:, label:, score_maximum:, resource_id: nil, resource_link_id: nil,
                                 tag: nil, start_date_time: nil, end_date_time: nil, grades_released: nil)
      existing = find_line_item(lineitems_url: lineitems_url,
                                resource_id: resource_id, resource_link_id: resource_link_id, tag: tag)
      return existing if existing

      new_li = LineItem.new(
        label: label,
        score_maximum: score_maximum,
        resource_id: resource_id,
        resource_link_id: resource_link_id,
        tag: tag,
        start_date_time: start_date_time,
        end_date_time: end_date_time,
        grades_released: grades_released
      )
      create_line_item(lineitems_url: lineitems_url, line_item: new_li)
    end

    def get_line_items(lineitems_url:, query: {})
      response = HTTParty.get(
        lineitems_url,
        headers: {
          "Authorization" => "Bearer #{@access_token}",
          "Accept"        => "application/vnd.ims.lis.v2.lineitemcontainer+json"
        },
        query: query
      )
      raise_api!(response)
      items = JSON.parse(response.body)
      items.map { |li| LineItem.new_from_api_response(li) }
    end

    def get_line_item(lineitem_id:)
      raise ArgumentError, "line item ID missing" unless lineitem_id

      response = HTTParty.get(
        lineitem_id,
        headers: {'Authorization' => "Bearer #{@access_token}",}
      )
      raise_api!(response)
      LineItem.new_from_api_response(JSON.parse(response.body))
    end

    def find_line_item(lineitems_url:, resource_link_id: nil, resource_id: nil, tag: nil)
      query = {}
      query[:resource_link_id] = resource_link_id if resource_link_id
      query[:resource_id]      = resource_id if resource_id
      query[:tag]              = tag if tag

      get_line_items(lineitems_url: lineitems_url, query: query).first
    end

    def create_line_item(lineitems_url:, line_item:)
      response = HTTParty.post(
        lineitems_url,
        headers: {
          'Authorization' => "Bearer #{@access_token}",
          'Content-Type' => 'application/vnd.ims.lis.v2.lineitem+json'
        },
        body:    line_item.to_json
      )
      raise_api!(response)
      response_data = JSON.parse(response.body)
      LineItem.new_from_api_response(response_data)
    end

    def update_line_item(lineitem_id:)
      raise ArgumentError, "line item ID missing" unless lineitem_id

      response = HTTParty.put(
        lineitem_id,
        headers: base_headers_json("application/vnd.ims.lis.v2.lineitem+json"),
        body:    line_item.to_json
      )
      raise_api!(response)
      LineItem.new_from_api_response(JSON.parse(response.body))
    end

    def delete_line_item(lineitem_id:)
      raise ArgumentError, "line item ID missing" unless lineitem_id

      response = HTTParty.delete(
        lineitem_id, 
        headers: {'Authorization' => "Bearer #{@access_token}",}
      )
      raise_api!(response)
      true
    end

    # Score Service
    
    def submit_score(score:, lineitem_id:)
      raise ArgumentError, "line item ID missing" unless lineitem_id

      score_url = build_lineitem_sub_url(lineitem_id, "scores")
      response = HTTParty.post(
        score_url,
        headers: {
          'Content-Type' => 'application/vnd.ims.lis.v1.score+json',
          'Authorization' => "Bearer #{@access_token}"
        },
        body: score.to_json
      )

      raise_api!(response)
      true
    end

    # Result Service

    def get_results(lineitem_id:, query: {})
      results_url = build_lineitem_sub_url(lineitem_id, "results")

      response = HTTParty.get(
        results_url,
        headers: {
          'Authorization' => "Bearer #{@access_token}",
          'Accept' => 'application/vnd.ims.lis.v2.resultcontainer+json'
        },
        query: query
      )
      
      raise_api!(response)
      results = JSON.parse(response.body)
      results.map { |res| Result.new_from_api_response(res) }
    end

    private

    def raise_api!(response)
      return if response.code.between?(200, 299)

      body_msg = response.body.to_s.strip
      raise "AGS API error: #{response.code}#{body_msg}"
    end

    def build_lineitem_sub_url(lineitem_id, suffix)
      uri = URI.parse(lineitem_id)
      query = uri.query
      uri.query = nil
      "#{uri}/#{suffix}#{query ? "?#{query}" : ''}"
    end

  end
end

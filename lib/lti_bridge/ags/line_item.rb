module LtiBridge
  class LineItem
    attr_accessor :id, :label, :score_maximum, :resource_id,
                  :resource_link_id, :tag, :start_date_time,
                  :end_date_time, :grades_released

    def initialize(label:, score_maximum:, resource_id: nil, resource_link_id: nil, tag: nil,
                   start_date_time: nil, end_date_time: nil, grades_released: nil, id: nil)
      @label = label
      @score_maximum = score_maximum
      @resource_id = resource_id
      @resource_link_id = resource_link_id
      @tag = tag
      @start_date_time = start_date_time
      @end_date_time = end_date_time
      @grades_released = grades_released
      @id = id
    end

    def to_h
      {
        id: @id,
        label: @label,
        scoreMaximum: @score_maximum,
        resourceId: @resource_id,
        resourceLinkId: @resource_link_id,
        tag: @tag,
        startDateTime: @start_date_time,
        endDateTime: @end_date_time,
        gradesReleased: @grades_released
      }.compact
    end

    def to_json(*_args)
      to_h.to_json
    end

    def save(access_token:, lineitems_url:) 
      response = HTTParty.post(lineitems_url,
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/vnd.ims.lis.v2.lineitem+json'
        },
        body: to_json
      )

      unless response.success?
        raise "Error creating line item: #{response.code} - #{response.body}"
      end

      response_data = JSON.parse(response.body)
      raise "Line item is not saved!" if response_data["id"].nil?
      self.id = response_data["id"] 
      self
    end

    def update(access_token:, **attributes)
      raise "Missing lineitem ID" unless id

      imutable_fields = [:id, :resource_id, :resource_link_id]

      attributes.each do |key, value|
        next if imutable_fields.include?(key.to_sym)
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end

      response = HTTParty.put(id,
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/vnd.ims.lis.v2.lineitem+json'
        },
        body: to_json
      )

      unless response.success?
        raise "Failed to update line item (ID: #{id}): #{response.code} - #{response.body}"
      end

      self
    end

    def delete(access_token:)
      raise "Missing lineitem ID" unless id

      response = HTTParty.delete(id, headers: {
        'Authorization' => "Bearer #{access_token}",
      })

      unless response.success?
        raise "Failed to delete line item (ID: #{id}): #{response.code} - #{response.body}"
      end
    end

    def self.find_or_create_by(
      access_token:, 
      lineitems_url:,  
      label:, 
      score_maximum:, 
      resource_id: nil, 
      resource_link_id: nil, 
      tag: nil,
      start_date_time: nil, 
      end_date_time: nil, 
      grades_released: nil
    )
      existing = find_by(
        access_token: access_token,
        lineitems_url: lineitems_url,
        resource_id: resource_id,
        resource_link_id: resource_link_id,
        tag: tag
      )

      return existing if existing

      new_item = new(
        label: label,
        score_maximum: score_maximum,
        resource_id: resource_id,
        resource_link_id: resource_link_id,
        tag: tag,
        start_date_time: start_date_time,
        end_date_time: end_date_time,
        grades_released: grades_released
      )

      new_item.save(access_token: access_token, lineitems_url: lineitems_url)
    end


    def self.find_by(access_token:, lineitems_url:, resource_link_id: nil, resource_id: nil, tag: nil)
      query = {}
      query[:resource_link_id] = resource_link_id if resource_link_id
      query[:resource_id] = resource_id if resource_id
      query[:tag] = tag if tag

      items = get_lineitems(access_token: access_token, lineitems_url: lineitems_url, query: query)
      items.first
    end

    def self.get_lineitems(access_token:, lineitems_url:, query: {})
      response = HTTParty.get(lineitems_url, headers: {
        'Authorization' => "Bearer #{access_token}",
        'Accept' => 'application/vnd.ims.lis.v2.lineitemcontainer+json'
        },
        query: query
      )

      items = JSON.parse(response.body)
      items.map { |item_data| new_from_api_response(item_data) }
    end


    def self.get(access_token:, lineitem_id:)
      response = HTTParty.get(lineitem_id, headers: {
        'Authorization' => "Bearer #{access_token}",
      })
      response_data = JSON.parse(response.body)
      new_from_api_response(response_data)
    end

    def self.new_from_api_response(data_hash)
      LineItem.new(
        id: data_hash['id'],
        label: data_hash['label'],
        score_maximum: data_hash['scoreMaximum'],
        resource_id: data_hash['resourceId'],
        resource_link_id: data_hash['resourceLinkId'],
        tag: data_hash['tag'],
        start_date_time: (Time.parse(data_hash['startDateTime']) if data_hash['startDateTime']),
        end_date_time: (Time.parse(data_hash['endDateTime']) if data_hash['endDateTime']),
        grades_released: data_hash['gradesReleased']
      )
    end

  end
end

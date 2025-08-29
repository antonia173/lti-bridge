module LtiBridge
  class LineItem
    attr_reader :id
    attr_accessor :label, :score_maximum, :resource_id,
                  :resource_link_id, :tag, :start_date_time,
                  :end_date_time, :grades_released

    attr_writer :id
    private :id=

    def initialize(label:, score_maximum:, resource_id: nil, resource_link_id: nil, tag: nil,
                   start_date_time: nil, end_date_time: nil, grades_released: nil)
      @label = label
      @score_maximum = score_maximum
      @resource_id = resource_id
      @resource_link_id = resource_link_id
      @tag = tag
      @start_date_time = start_date_time
      @end_date_time = end_date_time
      @grades_released = grades_released

      validate!
    end

    def to_h
      {
        id: @id,
        label: @label,
        scoreMaximum: @score_maximum,
        resourceId: @resource_id,
        resourceLinkId: @resource_link_id,
        tag: @tag,
        startDateTime: @start_date_time&.iso8601,
        endDateTime: @end_date_time&.iso8601,
        gradesReleased: @grades_released
      }.compact
    end

    def to_json(*_args)
      to_h.to_json
    end

    def self.new_from_api_response(data)
      li = LineItem.new(
        label: data['label'],
        score_maximum: data['scoreMaximum'],
        resource_id: data['resourceId'],
        resource_link_id: data['resourceLinkId'],
        tag: data['tag'],
        start_date_time: (Time.parse(data['startDateTime']) if data['startDateTime']),
        end_date_time: (Time.parse(data['endDateTime']) if data['endDateTime']),
        grades_released: data['gradesReleased']
      )

      li.id = data["id"]
      li
    end

    private

    def validate!
      raise ArgumentError, "label required" if @label.to_s.strip.empty?
      raise ArgumentError, "scoreMaximum must be > 0" unless @score_maximum && @score_maximum.to_f > 0

      if @start_date_time && @end_date_time && @end_date_time < @start_date_time
        raise ArgumentError, "end_date_time must be >= start_date_time"
      end

      unless [true, false, nil].include?(@grades_released)
        raise ArgumentError, "grades_released must be true/false or nil"
      end
    end

  end
end

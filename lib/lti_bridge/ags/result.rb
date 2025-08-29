module LtiBridge
  class Result
    attr_reader :id
    attr_accessor :score_of, :user_id, :result_score,
                  :result_maximum, :scoring_user_id, :comment

    def initialize(score_of:, user_id:, result_score: nil, result_maximum: 1.0, scoring_user_id: nil, comment: nil)
      @score_of = score_of
      @user_id = user_id
      @result_score = result_score
      @result_maximum = result_maximum || 1.0
      @scoring_user_id = scoring_user_id
      @comment = comment

      validate!
    end

    def to_h
      {
        id: @id,
        scoreOf: @score_of,
        userId: @user_id,
        resultScore: @result_score,
        resultMaximum: @result_maximum,
        scoringUserId: @scoring_user_id,
        comment: @comment
      }.compact
    end

    def to_json(*_args)
      to_h.to_json
    end

    
    def self.new_from_api_response(data)
      res = new(
        score_of: data['scoreOf'],
        user_id: data['userId'],
        result_score: data['resultScore'],
        result_maximum: data['resultMaximum'] || 1.0,
        scoring_user_id: data['scoringUserId'],
        comment: data['comment']
      )

      res.send(:set_id!, data["id"]) if data["id"]
      res
    end

    private

    def set_id!(value)
      @id = value
    end

    def validate!
      raise ArgumentError, "score_of required" if @score_of.to_s.strip.empty?
      raise ArgumentError, "user_id required"  if @user_id.to_s.strip.empty?

      unless @result_maximum.is_a?(Numeric) && @result_maximum > 0
        raise ArgumentError, "result_maximum must be > 0"
      end

      if @result_score
        unless @result_score.is_a?(Numeric)
          raise ArgumentError, "result_score must be numeric"
        end
        if @result_score < 0 || @result_score > @result_maximum
          raise ArgumentError, "result_score must be between 0 and result_maximum"
        end
      end
    end
  end
end

module LtiBridge
  class Result
    attr_accessor :id, :score_of, :user_id, :result_score,
                  :result_maximum, :scoring_user_id, :comment

    def initialize(id:, score_of:, user_id:, result_score: nil, result_maximum: 1.0, scoring_user_id: nil, comment: nil)
      @id = id
      @score_of = score_of
      @user_id = user_id
      @result_score = result_score
      @result_maximum = result_maximum || 1.0
      @scoring_user_id = scoring_user_id
      @comment = comment
    end

    def self.new_from_api_response(data)
      new(
        id: data['id'],
        score_of: data['scoreOf'],
        user_id: data['userId'],
        result_score: data['resultScore'],
        result_maximum: data['resultMaximum'] || 1.0,
        scoring_user_id: data['scoringUserId'],
        comment: data['comment']
      )
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

  end
end

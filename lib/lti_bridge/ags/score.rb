module LtiBridge
  class Score
    VALID_ACTIVITY_PROGRESS = %w[Initialized Started InProgress Submitted Completed].freeze
    VALID_GRADING_PROGRESS  = %w[FullyGraded Pending PendingManual Failed NotReady].freeze

    attr_accessor :timestamp, :score_given, :score_maximum, :activity_progress,
                  :grading_progress, :user_id, :scoring_user_id, :comment,
                  :submission_started_at, :submission_submitted_at

    def initialize(
      user_id:,
      activity_progress:,
      grading_progress:,
      score_given: nil,
      score_maximum: nil,
      scoring_user_id: nil,
      comment: nil,
      submission_started_at: nil,
      submission_submitted_at: nil
    )
      @timestamp = Time.now.utc.iso8601
      @user_id = user_id
      @activity_progress = activity_progress
      @grading_progress = grading_progress
      @score_given = score_given
      @score_maximum = score_maximum
      @scoring_user_id = scoring_user_id
      @comment = comment
      @submission_started_at = submission_started_at
      @submission_submitted_at = submission_submitted_at

      validate!
    end

    def to_h
      base = {
        timestamp: @timestamp,
        userId: @user_id,
        activityProgress: @activity_progress,
        gradingProgress: @grading_progress
      }

      base[:scoreGiven] = @score_given if @score_given
      base[:scoreMaximum] = @score_maximum if @score_given && @score_maximum
      base[:scoringUserId] = @scoring_user_id if @scoring_user_id
      base[:comment] = @comment if @comment

      if @submission_started_at || @submission_submitted_at
        base[:submission] = {}
        base[:submission][:startedAt] = @submission_started_at if @submission_started_at
        base[:submission][:submittedAt] = @submission_submitted_at if @submission_submitted_at
      end

      base
    end

    def to_json(*_args)
      to_h.to_json
    end


    private

    def validate!
      unless VALID_ACTIVITY_PROGRESS.include?(@activity_progress)
        raise ArgumentError, "Invalid activityProgress: #{@activity_progress}"
      end

      unless VALID_GRADING_PROGRESS.include?(@grading_progress)
        raise ArgumentError, "Invalid gradingProgress: #{@grading_progress}"
      end

      if @score_given && @score_maximum.nil?
        raise ArgumentError, "scoreMaximum must be provided if scoreGiven is present"
      end

      if @score_given.nil? && @score_maximum
        raise ArgumentError, "scoreGiven must be provided if scoreMaximum is present"
      end

      if @submission_started_at && !iso8601_valid?(@submission_started_at)
        raise ArgumentError, "submission_started_at must be valid ISO8601 timestamp"
      end

      if @submission_submitted_at && !iso8601_valid?(@submission_submitted_at)
        raise ArgumentError, "submission_submitted_at must be valid ISO8601 timestamp"
      end
    end

    def iso8601_valid?(str)
      Time.iso8601(str)
      true
    rescue ArgumentError
      false
    end
  end
end

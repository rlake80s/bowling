class GameSummary
  def initialize(users:, game:)
    @users = users
    @game = game
    @summary = {}
    users.each { |user| summary[user.name] = summary_template_copy }
  end

  def add_roll(user:, pins:, current_frame:)
    user_game = game[user.name]
    user_summary = summary[user.name]

    frame_str = user_game.length.to_s

    user_summary['frames'][frame_str] = current_frame.summary_dump
    user_summary['score'] += pins

    # don't add 11th frame bonus rolls as bonus
    if add_bonus?(user_game) && !current_frame.bonus_rolls
      last_frame_str = (user_game.length - 1).to_s
      last_game = user_game[user_game.length - 2]

      if last_game.a_strike? || (last_game.a_spare? && current_frame.second_roll.nil?)
        user_summary['frames'][last_frame_str]['bonus'] += pins
        user_summary['score'] += pins
      end

      last_last_game = user_game[user_game.length - 3]

      # add pins to last two frames bonus if last two frames were strikes
      if last_game.a_strike? && last_last_game && last_last_game.a_strike?
        last_last_frame_str = (user_game.length - 2).to_s
        user_summary['frames'][last_last_frame_str]['bonus'] += pins
        user_summary['score'] += pins
      end
    end
  end

  attr_reader :summary, :game

  private

  def add_bonus?(user_game)
    if user_game.length > 1
      last_frame_index = user_game.length - 2
      return user_game[last_frame_index].total == 10
    end

    false
  end

  def summary_template
    @template ||= begin
      template = {
        'score' => 0,
        'frames' => {}
      }
      10.times do |i|
        template['frames'][(i + 1).to_s] = {
          'first' => nil,
          'second' => nil,
          'bonus' => 0
        }
      end
      template
    end
  end

  def summary_template_copy
    Marshal.load(Marshal.dump(summary_template))
  end
end

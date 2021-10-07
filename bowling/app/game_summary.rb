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

    if frame_str == '11'
      handle_final_bonus_rolls(user_game, user_summary, pins, current_frame)
      return
    end

    user_summary['frames'][frame_str] = current_frame.summary_dump
    user_summary['score'] += pins

    if add_bonus?(user_game) && !current_frame.bonus_rolls
      handle_normal_bonus_rolls(user_game, user_summary, pins, current_frame)
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

  def handle_normal_bonus_rolls(user_game, user_summary, pins, current_frame)
    last_frame_str = (user_game.length - 1).to_s
    last_frame = user_game[user_game.length - 2]

    if last_frame.a_strike? || (last_frame.a_spare? && current_frame.second_roll.nil?)
      user_summary['frames'][last_frame_str]['bonus'] += pins
      user_summary['score'] += pins
    end

    last_last_frame = user_game[user_game.length - 3]

    # add pins to last two frames bonus if last two frames were strikes
    if last_frame.a_strike? && last_last_frame && last_last_frame.a_strike?
      if user_game.length - 2 > 0
        last_last_frame_str = (user_game.length - 2).to_s
        user_summary['frames'][last_last_frame_str]['bonus'] += pins
        user_summary['score'] += pins
      end
    end
  end

  def handle_final_bonus_rolls(user_game, user_summary, pins, current_frame)
    frame_str = '10' # bonus rolls attributed to frame 10
    last_frame = user_game[9]
    last_last_frame = user_game[8]

    user_summary['frames'][frame_str].delete('bonus') # no bonus in tenth frame

    if last_frame.a_spare?
      user_summary['frames'][frame_str]['third'] = pins
      user_summary['score'] += pins
    else
      if current_frame.second_roll
        user_summary['frames'][frame_str]['third'] = pins
        user_summary['score'] += pins
      else
        user_summary['frames'][frame_str]['second'] = pins
        user_summary['score'] += pins
        # if 9th frame a strike and 10th frame a strike, first bonus roll goes back to 9th
        if last_last_frame.a_strike?
          user_summary['frames']['9']['bonus'] += pins
          user_summary['score'] += pins
        end
      end
    end
  end
end

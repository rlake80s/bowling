require 'pry'
require 'pry-nav'

class GameSummary
  def initialize(users: ['guest'], game:)
    @users = users
    @game = game
    @summary = {}
    users.each { |user| summary[user] = summary_template }
  end

  def add_roll(user: 'guest', pins:, current_frame:)
    frame_str = game.length.to_s

    summary[user]['frames'][frame_str] = current_frame.summary_dump
    summary[user]['score'] += pins

    # don't add 11th frame bonus rolls as bonus
    if add_bonus? && !current_frame.bonus_rolls
      last_frame_str = (game.length - 1).to_s
      last_game = game[game.length - 2]

      if last_game.a_strike? || last_game.a_spare? && current_frame.second_roll.nil?
        summary[user]['frames'][last_frame_str]['bonus'] += pins
        summary[user]['score'] += pins
      end

      last_last_game = game[game.length - 3]

      # add pins to last two frames bonus if last two frames were strikes
      if last_game.a_strike? && last_last_game && last_last_game.a_strike?
        last_last_frame_str = (game.length - 2).to_s
        summary[user]['frames'][last_last_frame_str]['bonus'] += pins
        summary[user]['score'] += pins
      end
    end
  end

  attr_reader :summary, :game

  private

  def add_bonus?
    if game.length > 1
      last_frame_index = game.length - 2
      return game[last_frame_index].total == 10
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
end

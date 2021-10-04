require_relative 'frame'
require_relative 'game_summary'

class Tenpin
  class IllegalRoll < StandardError; end

  ILLEGAL_ROLL_MSG = 'more than 10 pins rolled for frame'.freeze

  def initialize
    @game = [Frame.new]
    @current_frame = game.last
    @game_summary = GameSummary.new(game: game)
  end

  def roll(pins)
    return if game_over?
    raise IllegalRoll.new, ILLEGAL_ROLL_MSG unless roll_legal? pins

    if roll_a_strike? pins
      current_frame.first_roll = pins
      game_summary.add_roll(pins: pins, current_frame: current_frame)
      next_frame
      return
    end

    if current_frame.first_roll?
      current_frame.first_roll = pins
      game_summary.add_roll(pins: pins, current_frame: current_frame)
    else
      current_frame.second_roll = pins
      game_summary.add_roll(pins: pins, current_frame: current_frame)
      next_frame
    end
  end

  def score
    summary['guest']['score']
  end

  def summary
    game_summary.summary
  end

  private

  attr_reader :game, :game_summary
  attr_accessor :current_frame

  def next_frame
    if last_frame?
      if should_add_bonus_rolls?
        bonus_rolls = current_frame.a_strike? ? 2 : 1
        game.push(Frame.new(bonus_rolls: bonus_rolls))
      end
    else
      game.push(Frame.new)
    end

    @current_frame = game.last # idempotent when not adding new frame
  end

  def last_frame?
    game.length > 9
  end

  def game_over?
    return false unless last_frame?

    if current_frame.bonus_rolls
      if current_frame.bonus_rolls == 2
        return true unless current_frame.second_roll.nil?
      elsif current_frame.bonus_rolls == 1
        return true unless current_frame.first_roll?
      end
    elsif current_frame.first_roll && current_frame.second_roll
      return true
    end

    false
  end

  def skip_frame?(frame)
    frame.first_roll.nil? || frame.bonus_rolls
  end

  def no_next_game?(next_game)
    next_game.nil? || next_game.first_roll.nil?
  end

  def should_add_bonus_rolls?
    current_frame.total == 10 && !current_frame.bonus_rolls
  end

  def roll_legal?(pins)
    return false if pins > 10

    unless current_frame.bonus_rolls
      return false if pins + current_frame.first_roll.to_i > 10
    end

    true
  end

  def roll_a_strike?(pins)
    pins == 10 && !current_frame.bonus_rolls
  end
end

require_relative 'frame'
require_relative 'game_summary'
require_relative 'user'

require 'pry'
require 'pry-nav'

class Tenpin
  class IllegalRoll < StandardError; end
  class GameOver < StandardError; end

  ILLEGAL_ROLL_MSG = 'more than 10 pins rolled for frame'.freeze
  GAME_OVER_MSG = 'game is over. please start a new game.'.freeze
  FIRST_ROLL = 'first'.freeze
  SECOND_ROLL = 'second'.freeze

  def initialize(users: [])
    users.push(User.new(name: 'guest')) if users.empty?
    @users = users

    @game = {}
    users.each { |user| game[user.name] = [] }

    @game_summary = GameSummary.new(users: users, game: game)

    @current_user_index = 0
    @current_user = users[@current_user_index]

    game[current_user.name].push(Frame.new)
    @current_frame = game[current_user.name].last
  end

  def roll(pins)
    raise GameOver.new, GAME_OVER_MSG if game_over?
    raise IllegalRoll.new, ILLEGAL_ROLL_MSG if roll_illegal? pins

    if roll_a_strike? pins
      score_roll(pins, FIRST_ROLL)
      next_frame
      return
    end

    if current_frame.first_roll?
      score_roll(pins, FIRST_ROLL)
    else
      score_roll(pins, SECOND_ROLL)
      next_frame
    end
  end

  def score
    score = {}
    summary.each { |user, summary| score[user] = summary['score'] }
    score
  end

  def summary
    game_summary.summary
  end

  attr_reader :current_user

  private

  attr_reader :game, :game_summary, :users
  attr_accessor :current_frame

  def next_frame
    if last_frame?
      # bonus rolls should fall to the same user
      if should_add_bonus_rolls?
        bonus_rolls = current_frame.a_strike? ? 2 : 1
        game[current_user.name].push(Frame.new(bonus_rolls: bonus_rolls))
      else
        unless game_over?
          next_user
          game[current_user.name].push(Frame.new)
        end
      end
    else
      next_user
      game[current_user.name].push(Frame.new)
    end

    @current_frame = game[current_user.name].last
  end

  def last_frame?
    game[current_user.name].length > 9
  end

  def game_over?
    @last_user ||= users.last
    game[@last_user.name].length > 9 && game[@last_user.name].last.complete?
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

  def roll_illegal?(pins)
    return true if pins > 10

    unless current_frame.bonus_rolls
      return true if pins + current_frame.first_roll.to_i > 10
    end

    false
  end

  def roll_a_strike?(pins)
    pins == 10 && !current_frame.bonus_rolls
  end

  def score_roll(pins, roll)
    if roll == FIRST_ROLL
      current_frame.first_roll = pins
    elsif roll == SECOND_ROLL
      current_frame.second_roll = pins
    end

    game_summary.add_roll(
      user: current_user,
      pins: pins,
      current_frame: current_frame
    )
  end

  def next_user
    next_index = @current_user_index + 1
    @current_user_index = next_index >= users.length ? 0 : next_index

    @current_user = users[@current_user_index]
  end
end

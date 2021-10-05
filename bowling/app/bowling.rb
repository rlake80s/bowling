require_relative 'tenpin'

class Bowling
  def initialize
    @users = []
    @game_summaries = []
    @active_game = nil
  end

  def add_user(name:)
    users.push(User.new(name: name))
  end

  def remove_user(name:)
    users - [name] # deletes duplicates
  end

  def start_game
    save_game_summary if active_game
    active_game = Tenpin.new(users: users)
  end

  def cancel_game(save_game: false)
    save_game_summary if save_game && active_game
    active_game = nil
  end

  def roll(pins)
    active_game.roll(pins)
  end

  def current_user
    active_game.current_user
  end

  attr_reader :users, :game_summaries
  attr_accessor :active_game

  private

  def save_game_summary
    game_summaries.push(active_game.summary)
  end
end

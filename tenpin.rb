require 'pry'
require 'pry-nav'
require 'pp'

class Tenpin
  def initialize
    @game = [Frame.new(number: 1)]
    @current_frame = game.last
  end

  def roll(pins)
    if last_frame?
      return if (
        current_frame.first_roll && current_frame.second_roll
      ) || 
      current_frame.first_roll == 10
    end

    if pins == 10 # strike
      current_frame.first_roll = pins
      next_frame
      return
    end

    if current_frame.first_roll?
      current_frame.first_roll = pins
    else
      current_frame.second_roll = pins
      next_frame
    end
  end

  def score
    score = 0

    game.each_with_index do |frame, i|
      if frame.total.nil?
        next
      end
      
      score += frame.total
    end

    score += calculate_bonus

    score
  end

  def game_summary
    game.each_with_index do |frame, i|
      summary[(i + 1).to_s] = {
        'first' => frame.first_roll,
        'second' => frame.second_roll
      }
    end

    summary['score'] = score
    summary['bonus'] = calculate_bonus
    
    summary
  end

  private

  attr_reader :game
  attr_accessor :current_frame

  def next_frame
    if !last_frame?
      game.push(Frame.new(number: current_frame.number + 1))
      @current_frame = game.last
    end
  end

  def last_frame?
    game.length > 9
  end

  def summary
    @summary ||= (
      template = {
        'score' => 0,
        'bonus' => 0,
      }
      10.times do |i|
        template[(i + 1).to_s] = {
          'first' => nil,
          'second' => nil,
        }
      end
      template
    )
  end

  def calculate_bonus
    bonus = 0

    game.each_with_index do |frame, i|
      if frame.total.nil?
        next
      end

      # binding.pry

      if frame.first_roll == 10 # strike
        unless game[i + 1].nil? || game[i + 1].first_roll.nil?
          bonus += game[i + 1].first_roll 
          if game[i + 1].second_roll
            bonus += game[i + 1].second_roll
          else
            unless game[i + 2].nil? || game[i + 2].first_roll.nil?
              bonus += game[i + 2].first_roll
            end
          end
        end
      elsif frame.total == 10 # spare
        unless game[i + 1].nil? || game[i + 1].first_roll.nil?
          bonus += game[i + 1].first_roll
        end
      end
    end

    bonus
  end
end

class Frame
  def initialize(number:)
    @first_roll = nil
    @second_roll = nil
    @number = number
  end

  def first_roll?
    first_roll.nil?
  end

  def total
    if second_roll.nil?
      first_roll
    else
      first_roll + second_roll
    end
  end

  attr_accessor :first_roll, :second_roll
  attr_reader :number
end

require 'minitest/autorun'

class TenpinTest < MiniTest::Unit::TestCase
  def setup
    @game ||= Tenpin.new
  end

  def test_it_calculates_score_correctly
    game.roll 10
    game.roll 10

    game.roll 2
    game.roll 5

    15.times { game.roll 0 }

    assert_equal 46, game.score
  end

  def test_it_calculates_score_correctly_when_strikes_included
    game.roll 10 # 10 + 1 + 2

    game.roll 1
    game.roll 2

    16.times { game.roll 0 }

    assert_equal 16, game.score
  end

  def test_it_calculates_score_correctly_when_spares_included
    game.roll 7
    game.roll 3

    game.roll 2

    13.times { game.roll 0 }

    assert_equal 14, game.score
  end

  def test_it_calculates_a_max_of_ten_frames
    100.times { game.roll 1 }

    assert_equal 20, game.score
  end

  def test_it_returns_an_accurate_game_summary_as_the_game_progresses
    mid_game_hash = {
      "score"=>40,
      "bonus"=>10,
      "1"=>{"first"=>5, "second"=>5},
      "2"=>{"first"=>5, "second"=>5},
      "3"=>{"first"=>5, "second"=>5},
      "4"=>{"first"=>nil, "second"=>nil},
      "5"=>{"first"=>nil, "second"=>nil},
      "6"=>{"first"=>nil, "second"=>nil},
      "7"=>{"first"=>nil, "second"=>nil},
      "8"=>{"first"=>nil, "second"=>nil},
      "9"=>{"first"=>nil, "second"=>nil},
      "10"=>{"first"=>nil, "second"=>nil}
    }

    6.times { game.roll 5 }
    assert_equal mid_game_hash, game.game_summary

    final_game_hash = {
      "score"=>55,
      "bonus"=>11,
      "1"=>{"first"=>5, "second"=>5},
      "2"=>{"first"=>5, "second"=>5},
      "3"=>{"first"=>5, "second"=>5},
      "4"=>{"first"=>1, "second"=>1},
      "5"=>{"first"=>1, "second"=>1},
      "6"=>{"first"=>1, "second"=>1},
      "7"=>{"first"=>1, "second"=>1},
      "8"=>{"first"=>1, "second"=>1},
      "9"=>{"first"=>1, "second"=>1},
      "10"=>{"first"=>1, "second"=>1}
    }

    14.times { game.roll 1 }
    assert_equal final_game_hash, game.game_summary
  end

  private

  attr_reader :game
end
require 'pp'

class Tenpin
  def initialize
    @game = [Frame.new]
    @current_frame = game.last
  end

  def roll(pins)
    return if game_over?    

    if pins == 10 && !current_frame.bonus_rolls # strike
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
      next if skip_frame? frame
      
      score += frame.total
    end

    score += calculate_bonus

    score
  end

  def game_summary
    game.each_with_index do |frame, i|
      summary['frames'][(i + 1).to_s] = {
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
    if last_frame?
      if should_add_bonus_rolls?
        bonus_rolls = current_frame.first_roll == 10 ? 2 : 1
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

  def summary
    @summary ||= (
      template = {
        'score' => 0,
        'bonus' => 0,
        'frames' => {},
      }
      10.times do |i|
        template['frames'][(i + 1).to_s] = {
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
      next if skip_frame? frame

      next_game = game[i + 1]
      next_next_game = game[i + 2]

      next if no_next_game? next_game

      if frame.first_roll == 10 # strike
          bonus += next_game.first_roll 
          if next_game.second_roll # handle chance for consecutive strikes
            bonus += next_game.second_roll
          else
            next if no_next_game? next_next_game
            bonus += next_next_game.first_roll
          end
      elsif frame.total == 10 # spare
        bonus += next_game.first_roll
      end
    end

    bonus
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

    return false
  end

  def skip_frame?(frame)
    frame.total.nil? || frame.bonus_rolls
  end

  def no_next_game?(next_game)
    next_game.nil? || next_game.first_roll.nil?
  end

  def should_add_bonus_rolls?
    current_frame.total == 10 && !current_frame.bonus_rolls
  end
end

class Frame
  def initialize(bonus_rolls: false)
    @first_roll = nil
    @second_roll = nil
    @bonus_rolls = bonus_rolls
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
  attr_reader :bonus_rolls
end

require 'minitest/autorun'

class TenpinTest < MiniTest::Unit::TestCase
  def setup
    @game ||= Tenpin.new
  end

  def test_it_calculates_score_correctly
    game.roll 1
    game.roll 2
    game.roll 3
    game.roll 4

    16.times { game.roll 0 }

    assert_equal 10, game.score
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

  def test_two_bonus_rolls_granted_if_final_frame_is_a_strike
    18.times { game.roll 0 }

    3.times { game.roll 10 }

    assert_equal 30, game.score
  end

  def test_one_bonus_roll_granted_if_final_frame_is_a_spare
    18.times { game.roll 0 }

    3.times { game.roll 5 }

    assert_equal 15, game.score
  end

  def test_it_returns_an_accurate_game_summary_as_the_game_progresses

    6.times { game.roll 5 }

    mid_game_hash = {
      "score"=>40,
      "bonus"=>10,
      "frames"=> {
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
    }

    assert_equal mid_game_hash, game.game_summary

    14.times { game.roll 1 }

    final_game_hash = {
      "score"=>55,
      "bonus"=>11,
      "frames"=> {
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
    }

    assert_equal final_game_hash, game.game_summary
  end

  def test_bonus_rolls_add_11th_frame_in_game_summary
    18.times { game.roll 0 }

    1.times { game.roll 10 }
    2.times { game.roll 1 }

    expected_bonus_key = {
      "first"=>1,
      "second"=>1,
    }

    assert_equal expected_bonus_key, game.game_summary['frames']['11']
    assert_equal 12, game.score
  end

  private

  attr_reader :game
end
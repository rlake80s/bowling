require 'minitest/autorun'
require 'pp'

require_relative '../src/tenpin'

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
      'guest' => {
        'score' => 40,
        'frames' => {
          '1' => { 'first' => 5, 'second' => 5, 'bonus' => 5 },
          '2' => { 'first' => 5, 'second' => 5, 'bonus' => 5 },
          '3' => { 'first' => 5, 'second' => 5, 'bonus' => 0 },
          '4' => { 'first' => nil, 'second' => nil, 'bonus' => 0 },
          '5' => { 'first' => nil, 'second' => nil, 'bonus' => 0 },
          '6' => { 'first' => nil, 'second' => nil, 'bonus' => 0 },
          '7' => { 'first' => nil, 'second' => nil, 'bonus' => 0 },
          '8' => { 'first' => nil, 'second' => nil, 'bonus' => 0 },
          '9' => { 'first' => nil, 'second' => nil, 'bonus' => 0 },
          '10' => { 'first' => nil, 'second' => nil, 'bonus' => 0 }
        }
      }
    }

    assert_equal mid_game_hash, game.summary

    14.times { game.roll 1 }

    final_game_hash = {
      'guest' => {
        'score' => 55,
        'frames' => {
          '1' => { 'first' => 5, 'second' => 5, 'bonus' => 5 },
          '2' => { 'first' => 5, 'second' => 5, 'bonus' => 5 },
          '3' => { 'first' => 5, 'second' => 5, 'bonus' => 1 },
          '4' => { 'first' => 1, 'second' => 1, 'bonus' => 0 },
          '5' => { 'first' => 1, 'second' => 1, 'bonus' => 0 },
          '6' => { 'first' => 1, 'second' => 1, 'bonus' => 0 },
          '7' => { 'first' => 1, 'second' => 1, 'bonus' => 0 },
          '8' => { 'first' => 1, 'second' => 1, 'bonus' => 0 },
          '9' => { 'first' => 1, 'second' => 1, 'bonus' => 0 },
          '10' => { 'first' => 1, 'second' => 1, 'bonus' => 0 }
        }
      }
    }

    assert_equal final_game_hash, game.summary
  end

  def test_bonus_rolls_add_11th_frame_in_game_summary
    18.times { game.roll 0 }

    1.times { game.roll 10 }
    2.times { game.roll 1 }

    expected_bonus_key = {
      'first' => 1,
      'second' => 1,
      'bonus' => 0
    }

    assert_equal expected_bonus_key, game.summary['guest']['frames']['11']
    assert_equal 12, game.score
  end

  def test_illegal_roll_error_raised_if_more_than_10_pins_rolled
    error = assert_raises(Tenpin::IllegalRoll) do
      1.times { game.roll 11 }
    end

    assert_equal Tenpin::ILLEGAL_ROLL_MSG, error.message
  end

  def test_illegal_roll_error_raised_if_more_than_10_pins_rolled_for_frame
    1.times { game.roll 9 }

    error = assert_raises(Tenpin::IllegalRoll) do
      1.times { game.roll 2 }
    end

    assert_equal Tenpin::ILLEGAL_ROLL_MSG, error.message
  end

  private

  attr_reader :game
end

class Frame
  def initialize(bonus_rolls: nil)
    @first_roll = nil
    @second_roll = nil
    @bonus_rolls = bonus_rolls
  end

  def first_roll?
    first_roll.nil?
  end

  def total
    first_roll.to_i + second_roll.to_i
  end

  def a_strike?
    first_roll == 10 && !bonus_rolls
  end

  def a_spare?
    !a_strike? && total == 10 && !bonus_rolls
  end

  def summary_dump
    {
      'first' => first_roll,
      'second' => second_roll,
      'bonus' => 0
    }
  end

  def complete?
    first_roll && (
      bonus_rolls == 1 ||
      (!bonus_rolls && first_roll == 10) ||
      second_roll
    )
  end

  attr_accessor :first_roll, :second_roll
  attr_reader :bonus_rolls
end

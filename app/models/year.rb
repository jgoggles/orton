class Year < ActiveRecord::Base
  has_many :weeks
  has_many :games, :through => :weeks
  has_many :game_details, :through => :games

  def wins
    wins = 0
    weeks.each do |week|
      wins += week.wins unless week.wins.nil?
    end
    wins
  end

  def losses
    losses = 0
    weeks.each do |week|
      losses += week.losses unless week.losses.nil?
    end
    losses
  end

  def pushes
    pushes = 0
    weeks.each do |week|
      pushes += week.pushes unless week.pushes.nil?
    end
    pushes
  end

  def total_plays
    wins + losses + pushes
  end

  def win_pct
    wins.to_f / total_plays
  end
end

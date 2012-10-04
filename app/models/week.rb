class Week < ActiveRecord::Base
  has_many :games
  belongs_to :year

  def self.current
    if Time.now < Week.first.start_date
      first
    else
      where("start_date <= ?", Time.now).where(["end_date >= ?", Time.now]).first
    end
  end

  def self.previous
    if current.name.to_i > 1
      week = find(current.id - 1)
    else
      self.current
    end
  end

  def self.next
    if current.name.to_i > 1
      week = find(current.id + 1)
    else
      self.current
    end
  end
end

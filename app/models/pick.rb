class Pick < ActiveRecord::Base
  belongs_to :game
  belongs_to :team

  class << self
    def record(offset = 0)
      package_result(where("spread_diff >= ? or spread_diff <= ?", offset, offset * -1))
    end

    def record_for_home(offset = 0)
      package_result(where("spread_diff >= ?", offset))
    end

    def record_for_home_at(offset = 0)
      package_result(where("spread_diff >= ? and spread_diff <= ?", offset, offset + 1))
    end

    def record_for_away(offset = 0)
      offset = offset * -1
      package_result(where("spread_diff <= ?", offset))
    end

    def record_for_away_at(offset = 0)
      offset = offset * -1
      package_result(where("spread_diff <= ? and spread_diff >= ?", offset, offset - 1))
    end

    def record_for_home_favorites(offset = 0)
      package_result(where("spread > 0").where("spread_diff >= ?", offset))
    end

    def record_for_home_favorites_at(offset = 0)
      package_result(where("spread > 0").where("spread_diff >= ? and spread_diff <= ?", offset, offset + 1))
    end

    def record_for_away_favorites(offset = 0)
      offset = offset * -1
      package_result(where("spread < 0").where("spread_diff <= ?", offset))
    end

    def record_for_away_favorites_at(offset = 0)
      offset = offset * -1
      package_result(where("spread < 0").where("spread_diff <= ? and spread_diff >= ?", offset, offset - 1))
    end

    def record_for_home_dogs(offset = 0)
      package_result(where("spread < 0").where("spread_diff >= ?", offset))
    end

    def record_for_home_dogs_at(offset = 0)
      package_result(where("spread < 0").where("spread_diff >= ? and spread_diff <= ?", offset, offset + 1))
    end

    def record_for_away_dogs(offset = 0)
      offset = offset * -1
      package_result(where("spread > 0").where("spread_diff <= ?", offset))
    end

    def record_for_away_dogs_at(offset = 0)
      offset = offset * -1
      package_result(where("spread > 0").where("spread_diff <= ? and spread_diff >= ?", offset, offset - 1))
    end

    def package_result(result_set)
      total = result_set.size
      wins = result_set.where("result = 1").size
      pct = (wins.to_f / total).round(2)
      puts "wins: #{wins}"
      puts "total: #{total}"
      puts pct
    end
  end
end

class GameDetail < ActiveRecord::Base
  CONFIDENCE = %w{***** **** *** ** *}
  HFA = 2.39

  belongs_to :game
  belongs_to :team
  belongs_to :year

  before_save :add_f_c_hfa
  before_save :add_sag_hfa
  before_save :add_srs_hfa

  attr_accessor :confidence_factor

  def add_f_c_hfa
    if self.f_c_score_changed? and self.is_home?
      self.f_c_score += HFA
    end
  end

  def add_sag_hfa
    if self.sag_score_changed? and self.is_home?
      self.sag_score += HFA
    end
  end

  def add_srs_hfa
    if self.srs_score_changed? and self.is_home?
      self.srs_score += HFA
    end
  end

  # attr_accessible :expected_score, :expected_spread, :yards_gained

  def last_two
    games = []
    [1, 2].each do |n|
      g = self.team.games.where("week_id = ?", self.game.week.id - n).first
      games << construct_sched_peek(g)
    end
    games
  end

  def next_two
    games = []
    [1, 2].each do |n|
      g = self.team.games.where("week_id = ?", self.game.week.id + n).first
      games << construct_sched_peek(g)
    end
    games
  end

  def construct_sched_peek(game)
    if game.nil?
      "bye"
    else
      opp = game.teams.where("team_id != ?", self.team.id).first
      div = opp.is_division_opponent(self.team) ? '**' : ''
      if game.winner == self.team and game.date < self.game.date
        r = "W"
      elsif game.winner != self.team and game.date < self.game.date
        r = "L"
      else
        r = ''
      end
      if game.home.team == self.team
        if game.date < self.game.date
          team_score = game.home.score
          opp_score = game.away.score
          if !game.home.spread.nil?
            spread_diff = ", #{team_score + game.home.spread - opp_score}"
          else
            spread_diff = ''
          end
          score = ", #{team_score}-#{opp_score}, #{game.home.spread}#{spread_diff}"
        else
          score = ''
        end
        opp.nickname.upcase + div + " #{r}#{score}"
      else
        if game.date < self.game.date
          team_score = game.away.score
          opp_score = game.home.score
          if !game.away.spread.nil?
            spread_diff = ", #{team_score + game.away.spread - opp_score}"
          else
            spread_diff = ''
          end
          score = ", #{team_score}-#{opp_score}, #{game.away.spread}#{spread_diff}"
        else
          score = ''
        end
        opp.nickname.downcase + div + " #{r}#{score}"
      end
    end
  end

  def avg_1
    a = [calc_diff("pt_diff_score"), calc_diff("ypp_score"), calc_diff("f_c_score"), calc_diff("sag_score"), calc_diff("srs_score")]
    # a = [calc_diff("pt_diff_score"), calc_diff("ypp_score"), calc_diff("sag_score")]
    s = a.inject( nil ) { |sum,x| sum ? sum+x : x }
    s / a.size
  end

  def avg_2
    a = [calc_diff("f_c_score"), calc_diff("sag_score"), calc_diff("srs_score")]
    # a = [calc_diff("sag_score")]
    s = a.inject( nil ) { |sum,x| sum ? sum+x : x }
    s / a.size
  end

  def avg_spread
    a = [calc_spread("pt_diff_score"), calc_spread("ypp_score"), calc_spread("f_c_score"), calc_spread("sag_score"), calc_spread("srs_score")]
    # a = [calc_spread("pt_diff_score"), calc_spread("ypp_score"), calc_spread("sag_score")]
    s = a.inject( nil ) { |sum,x| sum ? sum+x : x }
    s / a.size
  end

  def avg_spread_2
    a = [calc_spread("f_c_score"), calc_spread("sag_score"), calc_spread("srs_score")]
    # a = [calc_spread("sag_score")]
    s = a.inject( nil ) { |sum,x| sum ? sum+x : x }
    s / a.size
  end

  def calc_spread(attr)
    if self.game.away.send(attr).nil? or self.game.home.send(attr).nil?
      0
    else
      if self.is_home?
        self.game.away.send(attr) - self.game.home.send(attr)
      else
        self.game.home.send(attr) - self.game.away.send(attr)
      end
    end
  end

  def calc_diff(attr)
    if self.spread.nil?
      0
    else
      self.calc_spread(attr) - self.spread
    end
  end

  def calc_pr_diff(attr)
    if self.game.home.send(attr).nil? or self.game.away.send(attr).nil?
      0
    else
      if self.is_home?
        self.game.home.send(attr) - self.game.away.send(attr)
      else
        self.game.away.send(attr) - self.game.home.send(attr)
      end
    end
  end

  def result_ats
    opp = game.game_details.where("team_id != ?", team_id).first
    # if opp.team_id == 22 or opp.team_id == 23 or opp.team_id == 24
      puts game.date
    if (score + spread) > opp.score
      result = 1
    elsif (score + spread) < opp.score
      result = -1
    elsif (score + spread) == opp.score
      result = 0
    end
    result
    # end
  end

  def self.record_ats
    wins, losses, pushes = 0, 0, 0
    # where("is_home = 1").where("spread < 0").where("team_id = ?", Team.find_by_nickname("Cardinals")).each do |gd|
    where("is_home = 1").where("spread = 13").each do |gd|
      if gd.game.date >= Chronic.parse("Sept 1, 2000") and gd.game.date < Chronic.parse("Sept 1, 2011")
        result = gd.result_ats
        if result == 1
          wins += 1
        elsif result == -1
          losses += 1
        elsif result == 0
          pushes += 0
        end
      end
    end
    puts "#{wins} - #{losses} - #{pushes} - #{(wins.to_f/(wins+losses+pushes)).round(2)}"
  end
end

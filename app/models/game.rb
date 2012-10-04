class Game < ActiveRecord::Base
  attr_accessible :date, :week_id, :game_details_attributes, :spread, :over_under
  attr_accessor :spread, :over_under

  belongs_to :week
  has_many :game_details, :dependent => :destroy
  has_many :teams, :through => :game_details
  has_one :pick

  accepts_nested_attributes_for :game_details

  HFA = GameDetail::HFA
  PYTHAG_EXPONENT = 2.67

  def home
    game_details.where("is_home = ?", true).first
  end

  def away
    game_details.where("is_home = ?", false).first
  end

  def winner
    game_details.order("score DESC").first.team
  end

  def score
    score = {}
    score[:home] = { team: home.team.nickname, score: home.score }
    score[:away] = { team: away.team.nickname, score: away.score }
    score
  end

  def pythag(team)
    if team == home.team
      pf = home.score
      pa = away.score
    elsif team == away.team
      pf = away.score
      pa = home.score
    end

    (pf**PYTHAG_EXPONENT / (pf**PYTHAG_EXPONENT + pa**PYTHAG_EXPONENT)).round(3)
  end

  def generate_pick
    home = self.home
    away = self.away
    home.confidence_factor = 0
    away.confidence_factor = 0
    [home, away].each do |gd|
      if gd.off_scoring_rank < 10
        gd.confidence_factor += 1
      end

      if gd.def_scoring_rank < 15
        gd.confidence_factor += 1
      end
    end
    if home.confidence_factor > away.confidence_factor
      home.update_attributes(confidence: "*****")
    end
  end

  ANS_CONSTANT = -0.36
  ANS_HFA = 0.72

  class << self
    def generate_ans(week=Week.current, year=Year.last)
      # week.games.each do |game|
      #   home = game.home
      #   away = game.away

        # home_logit = ANS_CONSTANT + ANS_HFA + (0.46 * home.o_pass) + (0.25 * home.o_run) - (19.4 * home.o_int) -(19.4 * home.o_fum) - (0.62 * home.d_pass) - (0.25 * home.d_run) - (1.53 * home.pen_rate)
        # away_logit = ANS_CONSTANT + (0.46 * away.o_pass) + (0.25 * away.o_run) - (19.4 * away.o_int) -(19.4 * away.o_fum) - (0.62 * away.d_pass) - (0.25 * away.d_run) - (1.53 * away.pen_rate)

        home_logit = (0.46 * 7.1) + (0.25 * 3.5) - (19.4 * 0.024) -(19.4 * 0.028) - (0.62 * 6.5) - (0.25 * 4.0) - (1.53 * 0.39)
        away_logit = (0.46 * 6.0) + (0.25 * 3.7) - (19.4 * 0.030) -(19.4 * 0.026) - (0.62 * 4.3) - (0.25 * 3.3) - (1.53 * 0.41)

        home_chance = Math::E ** (ANS_CONSTANT + (ANS_HFA/2) + home_logit - away_logit)
        home_chance = (home_chance/(1 + home_chance)).round(2)
        away_chance = 1 - home_chance

        puts "home - #{home_chance}, away = #{away_chance}"

      # end
    end

    def generate_record(game_total, year, trailing=false)
      this_week = game_total + 1
      game_total = trailing ? 4 : game_total
      f = File.open("#{Rails.root}/public/lines/#{year}_#{game_total + 1}", 'w')
      f.puts "LINES GENERATED #{Time.now}\n\n"
      team_avgs = {}
      Team.all.each do |t|
        team_avgs[t.id] = {}
        if trailing
          team_avgs[t.id][:scored] = t.avg_pts_scored_trailing(game_total, year)
          team_avgs[t.id][:allowed] = t.avg_pts_allowed_trailing(game_total, year)
        else
          team_avgs[t.id][:scored] = t.avg_pts_scored(game_total, year)
          team_avgs[t.id][:allowed] = t.avg_pts_allowed(game_total, year)
        end
      end
      year_id = Year.find_by_name(year).id
      # wins, losses, pushes = 0, 0, 0
      where("week_name = ?", this_week).joins(:week).where("year_id = ?", year_id).each do |game|
        home_pts_scored = team_avgs[game.home.team.id][:scored]
        home_pts_allowed = team_avgs[game.home.team.id][:allowed]
        home_opp_pts_scored = 0.0
        home_opp_pts_allowed = 0.0

        game.home.team.games.where("week_name <= ?", game_total).joins(:week).where("year_id = ?", year_id).each do |g|
          unless g.week_name >= this_week
            opp = g.game_details.where("team_id != ?", game.home.team.id).first.team
            home_opp_pts_scored += team_avgs[opp.id][:scored]
            home_opp_pts_allowed += team_avgs[opp.id][:allowed]
          end
        end

        home_opp_pts_scored = home_opp_pts_scored / game_total
        home_opp_pts_allowed = home_opp_pts_allowed / game_total

        away_pts_scored = team_avgs[game.away.team.id][:scored]
        away_pts_allowed = team_avgs[game.away.team.id][:allowed]
        away_opp_pts_scored = 0.0
        away_opp_pts_allowed = 0.0

        game.away.team.games.where("week_name <= ?", game_total).joins(:week).where("year_id = ?", year_id).each do |g|
          unless g.week_name >= this_week
            opp = g.game_details.where("team_id != ?", game.away.team.id).first.team
            away_opp_pts_scored += team_avgs[opp.id][:scored]
            away_opp_pts_allowed += team_avgs[opp.id][:allowed]
          end
        end

        away_opp_pts_scored = away_opp_pts_scored / game_total
        away_opp_pts_allowed = away_opp_pts_allowed / game_total

        home_off_plus = home_pts_scored / home_opp_pts_allowed
        home_def_plus = home_pts_allowed / home_opp_pts_scored

        away_off_plus = away_pts_scored / away_opp_pts_allowed
        away_def_plus = away_pts_allowed / away_opp_pts_scored

        home_perf_fig = (home_off_plus + away_def_plus)/2
        away_perf_fig = (away_off_plus + home_def_plus)/2

        home_base_off = (home_pts_scored + away_pts_allowed)/2
        away_base_off = (away_pts_scored + home_pts_allowed)/2

        home_score = ((home_base_off * home_perf_fig) + (HFA/2)).round_point5
        away_score = ((away_base_off * away_perf_fig) - (HFA/2)).round_point5

        f.puts "#{game.away.team.nickname}: #{away_score}"
        game.away.update_attributes(pt_diff_score: away_score)
        f.puts "#{game.home.team.nickname}: #{home_score}"
        game.home.update_attributes(pt_diff_score: home_score)

        pred_spread = home_score - away_score
        # spread = game.away.spread
        # # > 0 diff is always a home pick and vice versa; dont question this youve already spent too much time
        # # thinking about it and testing it and its kosher
        # # it goes like this:
        # # if my line is bigger than the posted line (diff > 0) it means the home team is undervalued, and vice versa
        # # WE ARE ALWAY PICKING THE UNDERVALUED TEAM
        # spread_diff = pred_spread - spread
        f.puts "expected away line : #{pred_spread}"
        # # f.puts "actual away line: #{spread}"
        # # f.puts "spread diff: #{spread_diff}"
        # # f.puts "#{game.away.team.nickname}: #{away_score} - #{game.away.score}"
        # # f.puts "#{game.home.team.nickname}: #{home_score} - #{game.home.score}"

        # game.away.update_attributes(expected_score: away_score, expected_spread: pred_spread)
        # game.home.update_attributes(expected_score: home_score, expected_spread: (pred_spread * -1))

        # if pred_spread > 0
        #   if pred_spread - 5 >= spread
        #     pick = game.home
        #     opp = game.away
        #   elsif pred_spread + 5 <= spread
        #     pick = game.away
        #     opp = game.home
        #   end
        # else
        #   if pred_spread + 5 <= spread
        #     pick = game.away
        #     opp = game.home
        #   elsif pred_spread - 5 >= spread
        #     pick = game.home
        #     opp = game.away
        #   end
        # end
        # if pick
        #   # f.puts "pick: #{pick.team.nickname}: #{pick.is_home ? 'home' : 'away'}" 
        #   # if the pick is a home
        #   if spread_diff > 0
        #     if (pick.score - spread) > opp.score
        #       # f.puts "win"
        #       wins += 1
        #       result = 1
        #     elsif (pick.score - spread) < opp.score
        #       # f.puts "loss"
        #       losses +=1
        #       result = -1
        #     elsif (pick.score - spread) == opp.score
        #       # f.puts "push"
        #       pushes += 1
        #       result = 0
        #     end
        #   else
        #     if (pick.score + spread) > opp.score
        #       # f.puts "win"
        #       wins += 1
        #       result = 1
        #     elsif (pick.score + spread) < opp.score
        #       # f.puts "loss"
        #       losses +=1
        #       result = -1
        #     elsif (pick.score + spread) == opp.score
        #       # f.puts "push"
        #       pushes += 1
        #       result = 0
        #     end
        #   end
        #   Pick.create!(spread: spread, result: result, game_id: game.id, team_id: pick.team.id, spread_diff: spread_diff)
        # else
        #   # f.puts "no pick"
        # end

        # f.puts "YPP DATA"
        # ypp = Game.gen_ypp(game.away.team, game.home.team, game_total, year)
        # f.puts "#{game.away.team.nickname}: #{ypp[:away]}"
        # f.puts "#{game.home.team.nickname}: #{ypp[:home]}"
        # f.puts "expected YPP away line : #{(ypp[:home] - ypp[:away]).round_point5}"
        f.puts "#################################\n\n"
      end
      # w = Week.where("name = ?", game_total + 1).where("year_id = ?", year_id).first
      # w.wins = wins
      # w.losses = losses
      # w.pushes = pushes
      # w.save
      # puts "#{wins} - #{losses} - #{pushes} - #{wins.to_f/(wins+losses+pushes)}"
    end

    def generate_ypp_record(start_week, year)
      f = File.open("#{Rails.root}/public/lines/ypp#{year}_#{start_week + 1}", 'w')
      f.puts "LINES GENERATED #{Time.now}\n\n"
      trailing_weeks = 4
      if start_week < trailing_weeks
        trailing_weeks = start_week
      end
      year_id = Year.find_by_name(year).id
      ypp_totals = Team.gather_ypp_totals(start_week, trailing_weeks, year_id)
      wins, losses, pushes = 0, 0, 0
      where("week_name = ?", start_week + 1).joins(:week).where("year_id = ?", year_id).each do |game|
        a = ypp_totals[game.away.team_id][:total_yds_gained] + ypp_totals[game.home.team_id][:total_yds_allowed]
        b = ypp_totals[game.away.team_id][:total_pts_scored] + ypp_totals[game.home.team_id][:total_pts_allowed]
        c = ypp_totals[game.away.team_id][:total_yds_allowed] + ypp_totals[game.home.team_id][:total_yds_gained]
        d = ypp_totals[game.away.team_id][:total_pts_allowed] + ypp_totals[game.home.team_id][:total_pts_scored]

        adj_away = a/b
        adj_home = c/d

        adj_per_game_away = a/(trailing_weeks*2)
        adj_per_game_home = c/(trailing_weeks*2)

        away_score = ((adj_per_game_away / adj_away) - (HFA/2)).round_point5
        home_score = ((adj_per_game_home / adj_home) + (HFA/2)).round_point5
        # puts "#{away_score} - #{home_score}"
        pred_spread = home_score - away_score
        # spread = game.away.spread
        # > 0 diff is always a home pick and vice versa; dont question this youve already spent too much time
        # thinking about it and testing it and its kosher
        # it goes like this:
        # if my line is bigger than the posted line (diff > 0) it means the home team is undervalued, and vice versa
        # WE ARE ALWAY PICKING THE UNDERVALUED TEAM
        # spread_diff = pred_spread - spread
        f.puts "expected away line : #{pred_spread}"
        # f.puts "actual away line: #{spread}"
        # f.puts "spread diff: #{spread_diff}"
        f.puts "#{game.away.team.nickname}: #{away_score}"
        game.away.update_attributes(ypp_score: away_score)
        f.puts "#{game.home.team.nickname}: #{home_score}"
        game.home.update_attributes(ypp_score: home_score)
        # f.puts "#{game.away.team.nickname}: #{away_score} - #{game.away.score}"
        # f.puts "#{game.home.team.nickname}: #{home_score} - #{game.home.score}"

        # if pred_spread > 0
        #   if pred_spread - 5 >= spread
        #     pick = game.home
        #     opp = game.away
        #   elsif pred_spread + 5 <= spread
        #     pick = game.away
        #     opp = game.home
        #   end
        # else
        #   if pred_spread + 5 <= spread
        #     pick = game.away
        #     opp = game.home
        #   elsif pred_spread - 5 >= spread
        #     pick = game.home
        #     opp = game.away
        #   end
        # end
        # if pick
        #   f.puts "pick: #{pick.team.nickname}: #{pick.is_home ? 'home' : 'away'}" 
        #   # if the pick is a home
        #   if spread_diff > 0
        #     if (pick.score - spread) > opp.score
        #       f.puts "win"
        #       wins += 1
        #       result = 1
        #     elsif (pick.score - spread) < opp.score
        #       f.puts "loss"
        #       losses +=1
        #       result = -1
        #     elsif (pick.score - spread) == opp.score
        #       f.puts "push"
        #       pushes += 1
        #       result = 0
        #     end
        #   else
        #     if (pick.score + spread) > opp.score
        #       f.puts "win"
        #       wins += 1
        #       result = 1
        #     elsif (pick.score + spread) < opp.score
        #       f.puts "loss"
        #       losses +=1
        #       result = -1
        #     elsif (pick.score + spread) == opp.score
        #       f.puts "push"
        #       pushes += 1
        #       result = 0
        #     end
        #   end
        # else
        #   f.puts "no pick"
        # end
        f.puts "#################################\n\n"
      end
      # puts "#{wins} - #{losses} - #{pushes} - #{wins.to_f/(wins+losses+pushes)}"
    end

    def gen_ypp(away, home, start_week, year)
      score = {}
      a = away.total_yds_gained(start_week, t, year) + home.total_yds_allowed(start_week, t, year)
      b = away.total_pts_scored(start_week, t, year) + home.total_pts_allowed(start_week, t, year)
      c = away.total_yds_allowed(start_week, t, year) + home.total_yds_gained(start_week, t, year)
      d = away.total_pts_allowed(start_week, t, year) + home.total_pts_scored(start_week, t, year)

      adj_away = a/b
      adj_home = c/d

      adj_per_game_away = a/(t*2)
      adj_per_game_home = c/(t*2)

      score[:away] = (adj_per_game_away / adj_away) - 1.5
      score[:home] = (adj_per_game_home / adj_home) + 1.5

      score
    end

  end
end

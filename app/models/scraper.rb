require 'open-uri'
require 'nokogiri'
require 'watir-webdriver'

class Scraper

  URLS = {off_scoring: "http://www.teamrankings.com/nfl/stat/points-per-game",
    def_scoring: "http://www.teamrankings.com/nfl/stat/opponent-points-per-game",
    off_pass_eff: "http://www.teamrankings.com/nfl/stat/yards-per-pass-attempt",
    def_pass_eff: "http://www.teamrankings.com/nfl/stat/opponent-yards-per-pass-attempt",
    off_run_eff: "http://www.teamrankings.com/nfl/stat/yards-per-rush-attempt",
    def_run_eff: "http://www.teamrankings.com/nfl/stat/opponent-yards-per-rush-attempt",
    off_fumble_rate: "http://www.teamrankings.com/nfl/stat/fumbles-per-game",
    def_fumble_rate: "http://www.teamrankings.com/nfl/stat/opponent-fumbles-per-game",
    off_int_rate: "http://www.teamrankings.com/nfl/stat/pass-intercepted-pct",
    def_int_rate: "http://www.teamrankings.com/nfl/stat/interception-pct",
    off_penalty_rate: "http://www.teamrankings.com/nfl/team-stat/penalties-category",
    qb_sacked: "http://www.teamrankings.com/nfl/stat/qb-sacked-pct",
    qb_sacks: "http://www.teamrankings.com/nfl/stat/sack-pct"
  }

  ANS_URLS = {offense: "http://www.pro-football-reference.com/years/2012/",
    defense: "http://www.pro-football-reference.com/years/2012/opp.htm",
    d_penalties: "http://espn.go.com/nfl/statistics/team/_/stat/downs/position/defense",
    o_penalties: "http://espn.go.com/nfl/statistics/team/_/stat/downs"
  }

  class << self
    def get_ans_stats(week=Week.current.name, year=2012)

      offense = Nokogiri::HTML(open(ANS_URLS[:offense]))
      defense = Nokogiri::HTML(open(ANS_URLS[:defense]))
      d_penalties = Nokogiri::HTML(open(ANS_URLS[:d_penalties]))
      o_penalties = Nokogiri::HTML(open(ANS_URLS[:o_penalties]))

      teams = {}

      stats_1 = offense.css('table#team_stats tr')
      rushing = offense.css('table#rushing tr')
      stats_2 = defense.css('table#team_stats tr')
      stats_3 = d_penalties.css('#my-teams-table table tr')
      stats_4 = o_penalties.css('#my-teams-table table tr')

      total_pen_rate = 0.0

      stats_1.each do |team_row|
        next if team_row.at_css('td[2]').nil?
        team = team_row.at_css('td[2]').content
        team_object = Team.find_by_nickname(team.split(' ').last)
        teams[team] = {}

        rushing_row = rushing.find { |r| r.at_css('td[2]').content == team rescue next }
        defense_row = stats_2.find { |r| r.at_css('td[2]').content == team rescue next }

        unless team_object.nil?
          team_city = team == 'St. Louis Rams' ? 'St. Louis' : team_object.city
          d_penalty_row = stats_3.find { |r| r.at_css('td[2]').content.match(/#{team_city}|#{team_object.nickname}/) rescue next }
          o_penalty_row = stats_4.find { |r| r.at_css('td[2]').content.match(/#{team_city}|#{team_object.nickname}/) rescue next }
          plays = team_row.at_css('td[6]').content.to_f + defense_row.at_css('td[6]').content.to_f
          penalties_yds = d_penalty_row.at_css('td[14]').content.to_f + o_penalty_row.at_css('td[14]').content.to_f
          total_pen_rate += teams[team][:pen_rate] = penalties_yds / plays
        end

        teams[team][:o_pass] = team_row.at_css('td[14]').content.to_f
        teams[team][:o_run] = team_row.at_css('td[19]').content.to_f
        teams[team][:o_int] = (team_row.at_css('td[13]').content.to_f / team_row.at_css('td[10]').content.to_f).round(5)
        teams[team][:o_fum] = (rushing_row.at_css('td[10]').content.to_f / team_row.at_css('td[6]').content.to_f).round(5)
        teams[team][:d_pass] = defense_row.at_css('td[14]').content.to_f
        teams[team][:d_run] = defense.at_css('td[19]').content.to_f
      end

      teams["Avg Team"][:pen_rate] = total_pen_rate / 32

      year = Year.find_by_name year
      week = Week.where(name: week, year_id: year.id).first
      games = week.games

      games.each do |game|
        home = game.home
        home_team = home.team.full_name
        away = game.away
        away_team = away.team.full_name

        home_team = home_team == 'St Louis Rams' ? 'St. Louis Rams' : home_team
        away_team = away_team == 'St Louis Rams' ? 'St. Louis Rams' : away_team

        home.o_pass = teams[home_team][:o_pass]
        home.o_run = teams[home_team][:o_run]
        home.o_int = teams[home_team][:o_int]
        home.d_pass = teams[home_team][:d_pass]
        home.d_run = teams[home_team][:d_run]
        home.pen_rate = teams[home_team][:pen_rate]
        home.save

        away.o_pass = teams[away_team][:o_pass]
        away.o_run = teams[away_team][:o_run]
        away.o_int = teams[away_team][:o_int]
        away.d_pass = teams[away_team][:d_pass]
        away.d_run = teams[away_team][:d_run]
        away.pen_rate = teams[away_team][:pen_rate]
        away.save
      end

      teams["Avg Team"]
    end

    def parse_nfl_lines
      url = 'http://www.sportsinteraction.com/football/nfl-betting-lines/'

      doc = Nokogiri::HTML(open(url))

      rows = doc.css('div.game')
      lines = []

      if rows
        rows.each do |a|
          if !a.at_css('div ul[2] li[2] span span.handicap').nil?
            matchup = a.at_css('span.title a').content.match(/(.*)\sat\s(.*)/)
            away = $1.strip!
            home = $2.strip!

            away.gsub!("NY", "New York")
            away.gsub!(".", "")
            home.gsub!("NY", "New York")
            home.gsub!(".", "")

            line = a.at_css('div ul[2] li[2] span span.handicap').content
            over_under = a.at_css('div ul.twoWay[3] li[2] span span.handicap').content

            lines.push(Hash.new)
            lines[rows.index(a)]['game'] = {}
            lines[rows.index(a)]['game']['home'] = home
            lines[rows.index(a)]['game']['away'] = away
            lines[rows.index(a)]['game']['over_under'] = over_under.strip!.gsub("+", "")
            if line.strip.size == 2 && a.at_css('div ul[2] li[2] span span.price').content.strip.size == 2
              lines[rows.index(a)]['game']['line'] = :off
            elsif a.at_css('div ul[2] li[2] span span.price').content == "Closed"
              lines[rows.index(a)]['game']['line'] = :off
            elsif line.strip.size == 2 && a.at_css('div ul[2] li[2] span span.price').content != "Closed"
              lines[rows.index(a)]['game']['line'] = "0"
            else
              lines[rows.index(a)]['game']['line'] = line.strip!
            end
          else
            lines.push(Hash.new)
            lines[rows.index(a)]['game'] = {}
            lines[rows.index(a)]['game']['home'] = :off
            lines[rows.index(a)]['game']['away'] = :off
            lines[rows.index(a)]['game']['line'] = :off
          end
        end
      end

      lines
    rescue Exception => e
      print e, "\n"
    end

    def parse_nfl_scores(week)
      url = "http://www.nfl.com/scores/2011/REG#{week}"

      doc = Nokogiri::HTML(open(url))

      score_divs = doc.css('div.new-score-box')
      games = []

      score_divs.each do |score_div|
        parsed_home_team = score_div.at_css('div.home-team p.team-name a').content
        parsed_away_team = score_div.at_css('div.away-team p.team-name a').content
        home_score = score_div.at_css('div.home-team p.total-score').content
        away_score = score_div.at_css('div.away-team p.total-score').content

        home_team = Team.find_by_nickname(parsed_home_team).games.where("week = ?", week).first.home
        home_team.score = home_score
        home_team.save

        away_team = Team.find_by_nickname(parsed_away_team).games.where("week = ?", week).first.away
        away_team.score = away_score
        away_team.save
      end
    rescue Exception => e
      print e, "\n"
    end

    def parse_nfl_scores_espn(week, year=2012)
      url = "http://scores.espn.go.com/nfl/scoreboard?seasonYear=#{year}&seasonType=2&weekNumber=#{week}"
      year = Year.find_by_name(year)

      doc = Nokogiri::HTML(open(url))

      score_rows = doc.css('div.score-row')
      games = []

      score_rows.each do |score_row|
        score_divs = score_row.css('div.span-2')
        score_divs.each do |score_div|
          parsed_home_team = score_div.at_css('div.home div.team-capsule p').content
          parsed_away_team = score_div.at_css('div.visitor div.team-capsule p').content

          home_score = score_div.at_css('div.home ul.score li.final').content
          away_score = score_div.at_css('div.visitor ul.score li.final').content

          home_yards = score_div.at_css('div.stats-container div.first div.home p').content
          away_yards = score_div.at_css('div.stats-container div.first div.visitor p').content

          home_team = Team.find_by_nickname(parsed_home_team).games.where("week_name = ?", week).joins(:week).where("year_id = ?", year.id).first.home
          home_team.score = home_score
          home_team.yards_gained = home_yards
          home_team.yards_allowed = away_yards
          home_team.save

          away_team = Team.find_by_nickname(parsed_away_team).games.where("week_name = ?", week).joins(:week).where("year_id = ?", year.id).first.away
          away_team.score = away_score
          away_team.yards_gained = away_yards
          away_team.yards_allowed = home_yards
          away_team.save
        end
      end
    rescue Exception => e
      print e, "\n"
    end

    def get_stats(games = Week.current.games)

      URLS.each do |attr, url|
        stats = Scraper.stand_dev(url)
        browser = Watir::Browser.new
        browser.goto url
        sleep 5
        doc = Nokogiri::HTML(browser.html)
        team_rows = doc.css('tr[class^="div_"]')
        games.each do |game|
          game.game_details.each do |gd|
            if gd.team.nickname == "Giants"
              team = "NY Giants"
            elsif gd.team.nickname == "Jets"
              team = "NY Jets"
            else
              team = gd.team.city
            end
            team_rows.each do |team_row|
              page_team = team_row.at_css('td[2] a').content
              if page_team == team
                rank = team_row.at_css('td').content
                stat = team_row.at_css('td[3]').content
                sd = ((stat.to_f - stats[:mean]) / stats[:standard_deviation]).round(3)
                gd.update_attributes(attr.to_sym => stat, "#{attr}_rank".to_sym => rank, "#{attr}_sd".to_sym => sd)
              end
            end
          end
        end
        browser.close
      end
    end

    def stand_dev(url)
      # URLS.each do |attr, url|
        pop = 32
        n = 0
        v = 0
        browser = Watir::Browser.new
        browser.goto url
        sleep 5
        doc = Nokogiri::HTML(browser.html)
        team_rows = doc.css('tr[class^="div_"]')
        team_rows.each do |team_row|
          stat = team_row.at_css('td[3]').content.to_f
          n += stat
        end
        mean = n/pop
        team_rows.each do |team_row|
          stat = team_row.at_css('td[3]').content.to_f
          v += (stat - mean)**2
        end
        variance = v/pop
        standard_deviation = Math.sqrt(variance)

        puts "#{attr}"
        puts "Mean: #{mean}"
        puts "Variance: #{variance}"
        puts "Standard Dev: #{standard_deviation}"
        browser.close
        { mean: mean, variance: variance, standard_deviation: standard_deviation }
      # end
    end

  end
end



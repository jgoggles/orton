class Team < ActiveRecord::Base
  has_many :game_details
  has_many :games, :through => :game_details
  has_many :picks

  def full_name
    [city, nickname].join(" ")
  end

  def games_for_year(year = Year.last)
    self.games.where('date >= ?', year.weeks.first.start_date).select { |w| w.week_name.to_i < 18 }.sort_by { |w| w.week_name.to_i }
  end

  def unit_pythag(year = Year.last)
    pythags = games_for_year.inject([]) { |p, g| p << g.pythag(self) unless g.week.start_date >= Week.current.start_date; p }
    p_avg = pythags.inject(0.0) { |n, i| n + i } / pythags.size
    expected_wins = (16 * p_avg).round
    expected_losses = 16 - expected_wins
    {ew: expected_wins, el: expected_losses, ep: p_avg}
  end

  def record(year = Year.last)
    games = self.games_for_year(year)
    games.inject({w: 0, l: 0}) do |r, g|
      g.winner == self ? r[:w] += 1 : r[:l] += 1 unless g.week.start_date >= Week.current.start_date; r
    end
  end

  def is_division_opponent(team)
    self.conference_id == team.conference_id and self.division_id == team.division_id
  end

  def avg_pts_scored(game_total, year)
    pts_scored = 0.0
    games.where("week_name <= ?", game_total).joins(:week).where("year_id = ?", Year.find_by_name(year).id).each do |game|
      pts_scored += game.game_details.where("team_id = ?", self.id).first.score
    end
    pts_scored / game_total
  end

  def avg_pts_scored_trailing(game_total, year)
    pts_scored = 0.0
    games.where("week_name <= ?", game_total).where("week_name >= ?", game_total -4).joins(:week).where("year_id = ?", Year.find_by_name(year).id).each do |game|
      pts_scored += game.game_details.where("team_id = ?", self.id).first.score
    end
    pts_scored / game_total
  end

  def avg_pts_allowed(game_total, year)
    pts_allowed = 0.0
    games.where("week_name <= ?", game_total).joins(:week).where("year_id = ?", Year.find_by_name(year).id).each do |game|
      pts_allowed += game.game_details.where("team_id != ?", self.id).first.score
    end
    pts_allowed / game_total
  end

  def avg_pts_allowed_trailing(game_total, year)
    pts_allowed = 0.0
    games.where("week_name <= ?", game_total).where("week_name >= ?", game_total -4).joins(:week).where("year_id = ?", Year.find_by_name(year).id).each do |game|
      pts_allowed += game.game_details.where("team_id != ?", self.id).first.score
    end
    pts_allowed / game_total
  end

  def total_yds_gained(start_week, trailing_weeks, year_id)
    yards_gained = 0.0
    games.where("week_name <= ? and week_name >= ?", start_week, (start_week + 1) - trailing_weeks).joins(:week).where("year_id = ?", year_id).each do |game|
      yards_gained += game.game_details.where("team_id = ?", self.id).first.yards_gained
    end
    yards_gained
  end

  def total_yds_allowed(start_week, trailing_weeks, year_id)
    yards_allowed = 0.0
    games.where("week_name <= ?", start_week).where("week_name >= ?", ((start_week + 1) - trailing_weeks)).joins(:week).where("year_id = ?", year_id).each do |game|
      yards_allowed += game.game_details.where("team_id = ?", self.id).first.yards_allowed
    end
    yards_allowed
  end

  def total_pts_scored(start_week, trailing_weeks, year_id)
    points_scored = 0.0
    games.where("week_name <= ?", start_week).where("week_name >= ?", ((start_week + 1) - trailing_weeks)).joins(:week).where("year_id = ?", year_id).each do |game|
      points_scored += game.game_details.where("team_id = ?", self.id).first.score
    end
    points_scored
  end

  def total_pts_allowed(start_week, trailing_weeks, year_id)
    points_allowed = 0.0
    games.where("week_name <= ?", start_week).where("week_name >= ?", ((start_week + 1) - trailing_weeks)).joins(:week).where("year_id = ?", year_id).each do |game|
      points_allowed += game.game_details.where("team_id != ?", self.id).first.score
    end
    points_allowed
  end

  def not_active?
    ['Houston Oilers', 'Tennessee Oilers', 'Phoenix Cardinals', 'Los Angeles Rams', 'Los Angeles Raiders', 'St. Cardinals'].include? self.full_name
  end

  def self.unit_pythag(year = Year.last)
    self.all.inject({}) do |h, team|
      unless team.not_active?
        pythag = team.unit_pythag(year)
        record = team.record(year)
        h[team.nickname] = {ew: pythag[:ew], el: pythag[:el], e_perct: pythag[:ep].round(4), w: record[:w], l: record[:l], perct: (record[:w].to_f/(record[:w]+record[:l]) rescue 0), diff: (pythag[:ew] - record[:w])}
      end
      h
    end
  end

  def self.print_unit_pythag(pythag_hash, year = Year.last)
    printf('%-10s %3c %5s %3c %5s %3c %5s %3c %5s %3c %5s %3c %5s %3s %5s %3s', 'Team', '|', 'EW', '|', 'EL', '|', 'E%', '|', 'W', '|', 'L', '|', '%', '|', 'Diff', '|'); puts ''

    90.times { print '-' }; puts ''

    pythag_hash.sort_by { |p| -p[1][:diff] }.each do |team, wl|
      printf('%-10s %3c %5d %3c %5d %3c %5.4f %3c %5d %3c %5d %3c %5.4f %3s %5.4s %3s', team, '|', wl[:ew], '|', wl[:el], '|', wl[:e_perct].to_f, '|', wl[:w], '|', wl[:l], '|', wl[:perct], '|', wl[:e_perct] - wl[:perct], '|'); puts ''
    end

    nil
  end

  def self.gather_ypp_totals(start_week, trailing_weeks, year_id)
    team_totals = {}
    all.each do |t|
      team_totals[t.id] = {}
      team_totals[t.id][:total_yds_gained] = t.total_yds_gained(start_week, trailing_weeks, year_id)
      team_totals[t.id][:total_yds_allowed] = t.total_yds_allowed(start_week, trailing_weeks, year_id)
      team_totals[t.id][:total_pts_scored] = t.total_pts_scored(start_week, trailing_weeks, year_id)
      team_totals[t.id][:total_pts_allowed] = t.total_pts_allowed(start_week, trailing_weeks, year_id)
    end
    team_totals
  end

  def self.find_by_full_name(name)
    name_array = name.split(' ')
    city = name_array[0..-2].join(' ')
    nickname = name_array[-1]

    self.find_by_city_and_nickname(city, nickname)
  end

end

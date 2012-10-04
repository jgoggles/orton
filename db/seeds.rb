require 'csv'
require 'chronic'

ActiveRecord::Base.transaction do
  # Year.connection.execute("TRUNCATE years")
  # Week.connection.execute("TRUNCATE weeks")
  # Game.connection.execute("TRUNCATE games")
  # Game.connection.execute("TRUNCATE game_details")

  # (1991..2011).to_a.each do |y|
  #   Year.create!(name: y)
  # end

  # Dir.foreach("#{Rails.root}/public/csv") do |file|
  #   next if file == '.' or file == '..'
  #   puts "opening #{file}"
  #   CSV.foreach("#{Rails.root}/public/csv/#{file}") do |row|
  #     home = Team.find_by_full_name(row[3])
  #     away = Team.find_by_full_name(row[1])

  #     date = Chronic.parse("#{row[0]}")
  #     week = Week.where("start_date <= ?", date).where("end_date >= ?", date).first
  #     game = Game.create!(:date => date, :week_id => week.id, :week_name => week.name)
  #     GameDetail.create!(:game_id => game.id, :team_id => home.id, :is_home => true, :score => row[4], :spread => (row[5].to_f * -1))
  #     GameDetail.create!(:game_id => game.id, :team_id => away.id, :is_home => false, :score => row[2], :spread => (row[5].to_f))
  #     puts "created game info for #{home.nickname} vs #{away.nickname} on #{date}"
  #   end
  # end

  # t = Chronic.parse("Sept 4, 2012") - 12.hours
  # w = 0
  # 17.times do
  #   Week.create!(:name => w += 1, :start_date => t, :end_date => t + 1.week - 1.second, year_id: Year.last.id)
  #   t += 1.week
  # end

  CSV.foreach("#{Rails.root}/public/csv/NFL_2012_Complete.csv", {headers: :first_row}) do |row|
    puts row[16].strip
    home = Team.find_by_nickname(row[16].strip)
    puts row[15].strip
    away = Team.find_by_nickname(row[15].strip)
    date = Chronic.parse("#{row[0]} #{row[5]}")
    puts date
    week = Week.where("start_date <= ?", date).where("end_date >= ?", date).first
    game = Game.create!(:week_id => week.id, :date => date)
    game.update_attribute(:week_name, week.name)
    GameDetail.create!(:game_id => game.id, :team_id => home.id, :is_home => true)
    GameDetail.create!(:game_id => game.id, :team_id => away.id, :is_home => false)
  end
end

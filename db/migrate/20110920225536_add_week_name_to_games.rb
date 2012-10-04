class AddWeekNameToGames < ActiveRecord::Migration
  def change
    add_column :games, :week_name, :integer
  end
end

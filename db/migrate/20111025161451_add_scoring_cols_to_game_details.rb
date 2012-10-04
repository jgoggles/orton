class AddScoringColsToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :off_scoring, :float
    add_column :game_details, :def_scoring, :float
  end
end

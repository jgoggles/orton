class AddScoringRankColsToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :off_scoring_rank, :integer
    add_column :game_details, :def_scoring_rank, :integer
  end
end

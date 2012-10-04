class AddScoreToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :score, :integer
  end
end

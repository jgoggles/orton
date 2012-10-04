class AddExpectedScoresToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :expected_score, :float
  end
end

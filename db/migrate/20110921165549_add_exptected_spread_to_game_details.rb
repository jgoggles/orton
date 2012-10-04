class AddExptectedSpreadToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :expected_spread, :float
  end
end

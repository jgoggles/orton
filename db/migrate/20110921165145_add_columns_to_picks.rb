class AddColumnsToPicks < ActiveRecord::Migration
  def change
    add_column :picks, :spread, :float
    add_column :picks, :result, :integer
    add_column :picks, :game_id, :integer
    add_column :picks, :team_id, :integer
    add_column :picks, :expected_spread, :float
  end
end

class AddStatColsToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :off_pass_eff, :float
    add_column :game_details, :off_pass_eff_rank, :integer
    add_column :game_details, :def_pass_eff, :float
    add_column :game_details, :def_pass_eff_rank, :integer
    add_column :game_details, :off_run_eff, :float
    add_column :game_details, :off_run_eff_rank, :integer
    add_column :game_details, :def_run_eff, :float
    add_column :game_details, :def_run_eff_rank, :integer
    add_column :game_details, :off_fumble_rate, :float
    add_column :game_details, :off_fumble_rate_rank, :integer
    add_column :game_details, :def_fumble_rate, :float
    add_column :game_details, :def_fumble_rate_rank, :integer
    add_column :game_details, :off_int_rate, :float
    add_column :game_details, :off_int_rate_rank, :integer
    add_column :game_details, :def_int_rate, :float
    add_column :game_details, :def_int_rate_rank, :integer
    add_column :game_details, :off_penalty_rate, :float
    add_column :game_details, :off_penalty_rate_rank, :integer
  end
end

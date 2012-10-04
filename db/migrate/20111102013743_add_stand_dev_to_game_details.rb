class AddStandDevToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :off_scoring_sd, :float
    add_column :game_details, :def_scoring_sd, :float
    add_column :game_details, :off_pass_eff_sd, :float
    add_column :game_details, :def_pass_eff_sd, :float
    add_column :game_details, :off_run_eff_sd, :float
    add_column :game_details, :def_run_eff_sd, :float
    add_column :game_details, :off_fumble_rate_sd, :float
    add_column :game_details, :def_fumble_rate_sd, :float
    add_column :game_details, :off_int_rate_sd, :float
    add_column :game_details, :def_int_rate_sd, :float
    add_column :game_details, :off_penalty_rate_sd, :float
  end
end

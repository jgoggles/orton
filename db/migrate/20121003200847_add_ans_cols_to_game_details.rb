class AddAnsColsToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :o_pass, :float
    add_column :game_details, :o_run, :float
    add_column :game_details, :o_int, :float
    add_column :game_details, :o_fum, :float
    add_column :game_details, :d_pass, :float
    add_column :game_details, :d_run, :float
    add_column :game_details, :pen_rate, :float
  end
end

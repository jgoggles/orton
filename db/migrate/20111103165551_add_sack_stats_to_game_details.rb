class AddSackStatsToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :qb_sacked, :float
    add_column :game_details, :qb_sacked_sd, :float
    add_column :game_details, :qb_sacked_rank, :float
    add_column :game_details, :qb_sacks, :float
    add_column :game_details, :qb_sacks_sd, :float
    add_column :game_details, :qb_sacks_rank, :float
  end
end

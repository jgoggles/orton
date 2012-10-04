class AddGameMetaColumnsToGameDetails < ActiveRecord::Migration
  def change
    add_column :game_details, :su_record, :string
    add_column :game_details, :ats_record, :string
    add_column :game_details, :confidence, :string
    add_column :game_details, :pick, :boolean
    add_column :game_details, :result, :integer
    add_column :game_details, :sos, :float
    add_column :game_details, :pt_diff_score, :float
    add_column :game_details, :ypp_score, :float
    add_column :game_details, :f_c_score, :float
    add_column :game_details, :sag_score, :float
    add_column :game_details, :srs_score, :float
    add_column :game_details, :opening_line, :float
    add_column :game_details, :bet_percent, :float
    add_column :game_details, :ans, :integer
    add_column :game_details, :dvoa, :integer
  end
end

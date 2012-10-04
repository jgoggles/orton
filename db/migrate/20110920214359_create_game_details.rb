class CreateGameDetails < ActiveRecord::Migration
  def change
    create_table :game_details do |t|
      t.integer :game_id
      t.integer :team_id
      t.boolean :is_home
      t.float :spread
      t.integer :yards_gained
      t.integer :yards_allowed

      t.timestamps
    end
  end
end

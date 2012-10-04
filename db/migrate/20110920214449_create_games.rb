class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.datetime :date
      t.integer :week_id

      t.timestamps
    end
  end
end

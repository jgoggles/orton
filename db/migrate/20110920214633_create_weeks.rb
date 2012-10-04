class CreateWeeks < ActiveRecord::Migration
  def change
    create_table :weeks do |t|
      t.integer :name
      t.integer :year_id
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end

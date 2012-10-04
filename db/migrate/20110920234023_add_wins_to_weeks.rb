class AddWinsToWeeks < ActiveRecord::Migration
  def change
    add_column :weeks, :wins, :integer
    add_column :weeks, :losses, :integer
    add_column :weeks, :pushes, :integer
  end
end

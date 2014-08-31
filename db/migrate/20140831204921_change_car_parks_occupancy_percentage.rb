class ChangeCarParksOccupancyPercentage < ActiveRecord::Migration
  def change
    change_column :car_parks, :occupancy_percentage, :decimal, :precision => 16, :scale => 3
  end
end

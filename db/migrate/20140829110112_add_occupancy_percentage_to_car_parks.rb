class AddOccupancyPercentageToCarParks < ActiveRecord::Migration
  def change
    add_column :car_parks, :occupancy_percentage, :decimal, :decimal, :precision => 16, :scale => 3
  end
end

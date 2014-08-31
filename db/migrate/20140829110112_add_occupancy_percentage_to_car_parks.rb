class AddOccupancyPercentageToCarParks < ActiveRecord::Migration
  def change
    add_column :car_parks, :occupancy_percentage, :decimal
  end
end

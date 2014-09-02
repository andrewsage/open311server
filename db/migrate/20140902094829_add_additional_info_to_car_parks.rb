class AddAdditionalInfoToCarParks < ActiveRecord::Migration
  def change
    add_column :car_parks, :tariff, :string
    add_column :car_parks, :accessibility, :string
    add_column :car_parks, :address, :string
    add_column :car_parks, :operated_by, :string
  end
end

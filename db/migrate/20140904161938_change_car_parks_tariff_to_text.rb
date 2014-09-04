class ChangeCarParksTariffToText < ActiveRecord::Migration
  def change
    change_column :car_parks, :tariff, :text
  end
end

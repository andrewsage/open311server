class CreateCarParks < ActiveRecord::Migration
  def change
    create_table :car_parks do |t|
      t.string :id_public
      t.string :name
      t.decimal :lat
      t.decimal :long
      t.integer :occupancy
      t.integer :capacity
      t.datetime :data_updated
      t.timestamps
    end
  end
end

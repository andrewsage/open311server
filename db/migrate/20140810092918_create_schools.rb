class CreateSchools < ActiveRecord::Migration
  def change
    create_table :schools do |t|
      t.string :id_public
      t.string :name
      t.string :address
      t.string :post_code
      t.string :telephone
      t.string :fax
      t.string :web
      t.string :email
      t.string :school_type
      t.string :head_teacher
      t.decimal :lat
      t.decimal :long
      t.datetime :data_updated
      t.timestamps
    end
  end
end

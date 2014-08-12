class CreateCommunityCentres < ActiveRecord::Migration
  def change
    create_table :community_centres do |t|
      t.string :id_public
      t.string :name
      t.string :address
      t.string :post_code
      t.string :telephone
      t.string :fax
      t.string :web
      t.string :email
      t.text :brief_description
      t.text :description
      t.text :displayed_hours
      t.text :eligibility_information
      t.decimal :lat
      t.decimal :long
      t.datetime :data_updated
      t.timestamps
    end
  end
end

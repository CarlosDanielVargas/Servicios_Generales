class CreateRequestLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :request_locations do |t|
      t.string :name
      t.references :work_location, null: true, foreign_key: true
      t.references :request, null: false, foreign_key: true
      t.timestamps
    end
  end
end

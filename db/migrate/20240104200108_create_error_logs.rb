class CreateErrorLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :error_logs do |t|
      t.string :code
      t.string :description, null: false
      t.string :username

      t.timestamps
    end
  end
end

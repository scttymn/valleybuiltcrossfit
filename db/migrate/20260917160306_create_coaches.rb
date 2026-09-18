class CreateCoaches < ActiveRecord::Migration[8.1]
  def change
    create_table :coaches do |t|
      t.string :name
      t.string :role
      t.string :certification
      t.text :bio
      t.integer :position

      t.timestamps
    end
  end
end

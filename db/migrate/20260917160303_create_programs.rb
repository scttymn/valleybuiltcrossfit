class CreatePrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :programs do |t|
      t.string :key
      t.string :name
      t.text :blurb
      t.string :what_title
      t.text :what
      t.string :why_title
      t.text :why
      t.string :kicker
      t.string :cta
      t.integer :position

      t.timestamps
    end
  end
end

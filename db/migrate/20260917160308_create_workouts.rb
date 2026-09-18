class CreateWorkouts < ActiveRecord::Migration[8.1]
  def change
    create_table :workouts do |t|
      t.date :date
      t.string :name
      t.string :workout_type
      t.text :rx
      t.text :loads
      t.string :score
      t.string :source
      t.text :stimulus
      t.text :intermediate
      t.text :beginner

      t.timestamps
    end
    add_index :workouts, :date, unique: true
  end
end

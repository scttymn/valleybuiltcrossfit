class CreateSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :steps do |t|
      t.string :title
      t.text :body
      t.integer :position

      t.timestamps
    end
  end
end

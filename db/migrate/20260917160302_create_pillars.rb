class CreatePillars < ActiveRecord::Migration[8.1]
  def change
    create_table :pillars do |t|
      t.string :title
      t.string :body
      t.integer :position

      t.timestamps
    end
  end
end

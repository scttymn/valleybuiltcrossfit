class CreateMembershipOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :membership_options do |t|
      t.string :name
      t.string :description
      t.integer :position

      t.timestamps
    end
  end
end

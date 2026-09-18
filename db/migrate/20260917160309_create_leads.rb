class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :starting_from
      t.string :interest
      t.string :who
      t.text :notes

      t.timestamps
    end
  end
end

class AddUncappedClassTypesToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :uncapped_class_types, :string
  end
end

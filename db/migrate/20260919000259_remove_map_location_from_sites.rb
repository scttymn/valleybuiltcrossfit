class RemoveMapLocationFromSites < ActiveRecord::Migration[8.1]
  # The map is a static SVG now (script/build_map.rb), which carries the gym's
  # location itself.
  def change
    remove_column :sites, :map_latitude, :decimal, precision: 10, scale: 7
    remove_column :sites, :map_longitude, :decimal, precision: 10, scale: 7
  end
end

class AddMapLocationToSites < ActiveRecord::Migration[8.1]
  def up
    add_column :sites, :map_latitude, :decimal, precision: 10, scale: 7
    add_column :sites, :map_longitude, :decimal, precision: 10, scale: 7

    # The gym's building, from OpenStreetMap, for a site already at that address.
    execute <<~SQL
      UPDATE sites SET map_latitude = 39.0251858, map_longitude = -94.2158759
      WHERE address_line1 = '1450 NW Olympic Drive'
    SQL
  end

  def down
    remove_column :sites, :map_longitude
    remove_column :sites, :map_latitude
  end
end

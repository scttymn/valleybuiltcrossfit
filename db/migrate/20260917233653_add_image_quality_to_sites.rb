class AddImageQualityToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :image_quality, :integer
  end
end

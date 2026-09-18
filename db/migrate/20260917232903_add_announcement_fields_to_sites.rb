class AddAnnouncementFieldsToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :announcement_url, :string
    add_column :sites, :announcement_visible, :boolean
  end
end

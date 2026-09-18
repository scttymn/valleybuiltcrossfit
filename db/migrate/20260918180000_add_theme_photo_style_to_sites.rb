class AddThemePhotoStyleToSites < ActiveRecord::Migration[8.1]
  # nil means Theme::DEFAULT_PHOTO_STYLE.
  def change
    add_column :sites, :theme_photo_style, :string
  end
end

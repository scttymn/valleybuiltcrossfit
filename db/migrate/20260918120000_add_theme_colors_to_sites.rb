class AddThemeColorsToSites < ActiveRecord::Migration[8.1]
  # nil means "use Theme::DEFAULTS", so existing sites keep today's look.
  def change
    add_column :sites, :theme_background, :string
    add_column :sites, :theme_text, :string
    add_column :sites, :theme_accent, :string
  end
end

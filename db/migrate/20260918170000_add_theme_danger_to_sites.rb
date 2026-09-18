class AddThemeDangerToSites < ActiveRecord::Migration[8.1]
  # nil means Theme::DEFAULTS[:danger].
  def change
    add_column :sites, :theme_danger, :string
  end
end

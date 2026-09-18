class AddThemeBorderWidthToSites < ActiveRecord::Migration[8.1]
  # nil means Theme::DEFAULT_BORDER_WIDTH.
  def change
    add_column :sites, :theme_border_width, :integer
  end
end

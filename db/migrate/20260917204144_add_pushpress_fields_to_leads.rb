class AddPushpressFieldsToLeads < ActiveRecord::Migration[8.1]
  def change
    add_column :leads, :pushpress_customer_id, :string
    add_column :leads, :pushpress_error, :string
    add_column :leads, :synced_at, :datetime
  end
end

class RemovePushpressCustomerIdFromLeads < ActiveRecord::Migration[8.1]
  def change
    remove_column :leads, :pushpress_customer_id, :string
  end
end

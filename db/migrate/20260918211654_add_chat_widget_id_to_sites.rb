class AddChatWidgetIdToSites < ActiveRecord::Migration[8.1]
  def up
    add_column :sites, :chat_widget_id, :string

    # The gym's PushPress Grow chat widget ("Have a question?"), for a site
    # already at the gym's address.
    execute <<~SQL
      UPDATE sites SET chat_widget_id = '6aadb116599f010aecda2679'
      WHERE address_line1 = '1450 NW Olympic Drive'
    SQL
  end

  def down
    remove_column :sites, :chat_widget_id
  end
end

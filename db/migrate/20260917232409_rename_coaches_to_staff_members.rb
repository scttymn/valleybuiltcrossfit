class RenameCoachesToStaffMembers < ActiveRecord::Migration[8.1]
  def up
    rename_table :coaches, :staff_members
    add_column :staff_members, :kind, :string, null: false, default: "coach"
    add_column :staff_members, :certification_label, :string

    # The owners were a one-off block in Site; they become a staff member.
    site = execute("SELECT * FROM sites LIMIT 1").first
    if site && site["owners_names"].present?
      execute(<<~SQL.squish)
        INSERT INTO staff_members (name, role, certification, certification_label, bio, kind, position, created_at, updated_at)
        VALUES (
          #{quote(site["owners_names"])},
          #{quote(site["owners_label"].presence || "Owners")},
          #{quote(site["owners_cert"])},
          #{quote(site["owners_cert_label"])},
          #{quote(site["owners_bio"])},
          'owner', 0, #{quote(Time.current)}, #{quote(Time.current)}
        )
      SQL

      # Carry the owners photo over to the new record.
      owner_id = execute("SELECT id FROM staff_members WHERE kind = 'owner' ORDER BY id DESC LIMIT 1").first["id"]
      execute(<<~SQL.squish)
        UPDATE active_storage_attachments
        SET record_type = 'StaffMember', record_id = #{owner_id}, name = 'photo'
        WHERE record_type = 'Site' AND name = 'owners_photo'
      SQL
    end

    execute("UPDATE active_storage_attachments SET record_type = 'StaffMember' WHERE record_type = 'Coach'")

    remove_column :sites, :owners_label, :string
    remove_column :sites, :owners_names, :string
    remove_column :sites, :owners_bio, :text
    remove_column :sites, :owners_cert_label, :string
    remove_column :sites, :owners_cert, :string
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

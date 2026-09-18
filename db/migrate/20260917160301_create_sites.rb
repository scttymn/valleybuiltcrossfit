class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :announcement
      t.string :phone
      t.string :email
      t.string :instagram_url
      t.string :address_line1
      t.string :address_line2
      t.string :city_state_zip
      t.string :opening_note
      t.string :hero_eyebrow
      t.string :hero_title
      t.string :hero_title_accent
      t.text :hero_body
      t.string :hero_tags
      t.string :programs_intro
      t.string :steps_eyebrow
      t.string :steps_title
      t.string :schedule_intro
      t.string :dropin_title
      t.text :dropin_body
      t.string :dropin_why_title
      t.text :dropin_why_body
      t.string :dropin_price
      t.string :dropin_price_note
      t.string :dropin_url
      t.string :membership_title
      t.text :membership_body
      t.string :membership_rate_note
      t.string :owners_label
      t.string :owners_names
      t.text :owners_bio
      t.string :owners_cert_label
      t.string :owners_cert
      t.string :faq_intro
      t.string :visit_title
      t.string :visit_script
      t.string :pushpress_subdomain
      t.integer :class_capacity
      t.string :lead_notification_email

      t.timestamps
    end
  end
end

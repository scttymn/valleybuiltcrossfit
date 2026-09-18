require "test_helper"

# A fresh server gets its content and photos from db/seeds.rb, and nothing else
# exercises that file — a mistyped lookup once shipped an empty Recovery Studio
# card to production before anyone noticed it by eye.
class SeedsTest < ActiveSupport::TestCase
  setup do
    [ StaffMember, Program, Pillar, Step, MembershipOption, Faq, Site ].each(&:delete_all)
    ActiveStorage::Attachment.delete_all
    Rails.application.load_seed
  end

  test "a fresh install comes up with every section filled in" do
    assert Site.instance.hero_title.present?
    assert_equal 3, Program.count
    assert_equal 5, StaffMember.count
    [ Pillar, Step, MembershipOption, Faq ].each do |model|
      assert model.any?, "#{model.name} was left empty"
    end
  end

  test "a fresh install comes up with its photos attached" do
    assert Site.instance.hero_photo.attached?, "hero photo"

    Program.find_each do |program|
      assert program.photo.attached?, "#{program.name} has no photo"
    end

    [ "Jessica & Greg Isaacson", "Chad Worman", "Chris Neske" ].each do |name|
      assert StaffMember.find_by(name:).photo.attached?, "#{name} has no photo"
    end
  end
end

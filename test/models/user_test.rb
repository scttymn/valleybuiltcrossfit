require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  def build(password) = User.new(email_address: "new@example.com", password:)

  test "a password shorter than the minimum is refused, whatever sets it" do
    assert_not build("Ab1!" + "c" * (User::MINIMUM_PASSWORD_LENGTH - 5)).valid?
    assert build("Ab1!" + "c" * (User::MINIMUM_PASSWORD_LENGTH - 4)).valid?
  end

  test "a password must carry a capital, a number and a special character" do
    assert build("Passw0rd!").valid?

    assert_not build("passw0rd!").valid?, "no capital"
    assert_not build("Password!").valid?, "no number"
    assert_not build("Passw0rdx").valid?, "no special character"
  end

  test "the rejection names what was missing, not the whole policy" do
    user = build("password")
    user.validate

    assert_equal [ "Password must include a capital letter, a number, and a special character" ],
                 user.errors.full_messages.grep(/must include/)
  end

  test "saving an account without touching the password still works" do
    user = users(:one)
    user.email_address = "moved@example.com"
    assert user.save, user.errors.full_messages.to_sentence
  end
end

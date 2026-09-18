namespace :admin do
  desc "Create an admin user (prompts for email and password)"
  task create: :environment do
    require "io/console"
    print "Email: "
    email = $stdin.gets.to_s.strip
    print "Password (#{User::MINIMUM_PASSWORD_LENGTH}+ characters, with #{User::PASSWORD_RULES.keys.to_sentence}): "
    password = $stdin.noecho(&:gets).to_s.strip
    puts

    user = User.new(email_address: email, password:)
    if user.save
      puts "Created admin #{user.email_address}. Sign in at /login"
    else
      abort user.errors.full_messages.to_sentence
    end
  end
end

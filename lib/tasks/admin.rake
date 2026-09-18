namespace :admin do
  desc "Create an admin user (prompts for email and password)"
  task create: :environment do
    require "io/console"
    print "Email: "
    email = $stdin.gets.to_s.strip
    print "Password (min 12 characters): "
    password = $stdin.noecho(&:gets).to_s.strip
    puts

    user = User.new(email_address: email, password:)
    if password.length < 12
      abort "Password is too short."
    elsif user.save
      puts "Created admin #{user.email_address}. Sign in at /session/new"
    else
      abort user.errors.full_messages.to_sentence
    end
  end
end

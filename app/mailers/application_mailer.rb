class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Valley Built CrossFit <no-reply@valleybuiltcrossfit.com>")
  layout "mailer"
end

namespace :db do
  desc "Seed the design's content, but only on a site that has never been set up"
  task seed_once: :environment do
    # db:prepare seeds only a database it created itself, so a first boot that
    # fails after creating the database leaves one that never gets seeded. This
    # runs on every boot and decides for itself: a site with a headline has been
    # set up, and its content — including anything the admin has since deleted —
    # is left alone.
    if Site.instance.hero_title.present?
      puts "Site already set up, skipping seeds."
    else
      puts "Fresh site, loading seeds."
      Rails.application.load_seed
    end
  end
end

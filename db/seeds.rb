# Seeds the site with the copy from the Claude Design file. Safe to re-run:
# content is only created when a table is empty, so admin edits are kept.

site = Site.instance
if site.hero_title.blank?
  site.update!(
    announcement: "Opening October 5, 2026 \u2022 1450 NW Olympic Dr, Unit D \u2022 (816) 355-6595",
    announcement_visible: true,
    phone: "(816) 355-6595",
    email: "jessica@valleybuiltcrossfit.com",
    lead_notification_email: "jessica@valleybuiltcrossfit.com",
    instagram_url: "https://www.instagram.com/valleybuiltcrossfit",
    address_line1: "1450 NW Olympic Drive",
    address_line2: "Unit D",
    city_state_zip: "Grain Valley, MO 64029",
    map_latitude: 39.0251858,
    map_longitude: -94.2158759,
    hero_eyebrow: "Grain Valley, Missouri",
    hero_title: "Come as you are.",
    hero_title_accent: "Build from here.",
    hero_body: "Coached CrossFit classes for every body in the valley. Functional fitness, real strength, and a room full of people who know your name.",
    hero_tags: "All fitness levels / 60-minute classes / Coach-led, always",
    programs_intro: "Pick a program to read more about it.",
    steps_eyebrow: "Ready to join?",
    steps_title: "Here's what happens",
    schedule_intro: "Tap any class to see the coach, spots left, and reserve your place.",
    dropin_title: "What is drop-in?",
    dropin_body: "Drop-in passes allow out-of-town CrossFitters to train at Valley Built CrossFit for a single session. Show up ready to move, meet the community, and get a professionally guided, challenging workout. It's perfect for staying on track while visiting or testing out a new fitness atmosphere.",
    dropin_why_title: "Why members love this program",
    dropin_why_body: "Visiting athletes love our easy sign-up process and smooth integration into classes—no hassle or awkward introductions. Coaches ensure you feel respected, welcomed, and briefed on gym standards. Classes are both challenging and community-focused, so you stay motivated even as a guest. We're known for our professionalism and friendly environment—a drop-in at Valley Built is always a highlight of your trip.",
    dropin_price: "$25.00",
    dropin_price_note: "Single session for visiting athletes.",
    dropin_url: "https://valleybuiltcrossfit.pushpress.com/landing/plans/plan_3e63808b840344/login",
    membership_title: "Let's find the right\nfit for you.",
    membership_body: "There's no single right membership — it depends on how often you want to train, whether you're brand new, and who else in your house is coming with you. Tell us a bit about yourself and we'll send the options that actually apply to you.",
    membership_rate_note: "Memberships start at $75/mo for new athletes",
    visit_title: "Built in the valley.",
    visit_script: "Strong for life.",
    pushpress_subdomain: "valleybuiltcrossfit",
    class_capacity: 18,
    chat_widget_id: "6aadb116599f010aecda2679",
    image_quality: 80,
    uncapped_class_types: "General"
  )
end

if Pillar.none?
  [
    [ "Fitness", "Every workout scaled to you, coached start to finish." ],
    [ "Community", "People doing life together, five days a week." ],
    [ "Recovery", "Mobility, rest days and coaching that keeps you training." ],
    [ "Belonging", "No experience needed. No one gets left on the whiteboard." ]
  ].each { |title, body| Pillar.create!(title:, body:) }
end

if Program.none?
  Program.create!(
    key: "crossfit", name: "CrossFit", cta: "schedule",
    blurb: "Constantly varied workouts combining strength, cardio and flexibility — coach-led and scaled for any ability.",
    what_title: "What is CrossFit?",
    what: "CrossFit at Valley Built CrossFit is a dynamic group fitness program that combines strength training, cardio, and flexibility work in constantly varied workouts. Each class is led by certified coaches who scale the intensity and movements for any ability, helping total beginners and advanced athletes alike. Designed for anyone wanting to improve functional strength, endurance, and confidence, CrossFit classes here are about growth, not intimidation.",
    why_title: "Why members love this program",
    why: "Members love our CrossFit program for its expert coaching, clear programming, and inclusive atmosphere—you never feel lost or left behind. Each workout is different and challenging, making fitness rewarding and never monotonous. The accountability from our community ensures you stay consistent, enjoy the process, and make real progress. Coaches focus on safety and form, so you develop movement confidence you'll use for life. Everyone finds encouragement and camaraderie—come for fitness, stay for friendship."
  )
  Program.create!(
    key: "recovery", name: "Recovery Studio", cta: "",
    blurb: "LIT Method sauna and cold plunges — contrast therapy to help you recover between sessions.",
    what_title: "What is the Recovery Studio?",
    what: "Our Recovery Studio is a dedicated space to slow down, recharge, and take care of your body outside of your workout. Featuring LIT Method sauna and cold plunges, the studio gives you access to contrast therapy—the practice of alternating between heat and cold exposure to support your body's natural recovery process. Whether you train hard or simply want to feel and recover better, it's another way to invest in your health beyond the gym floor.",
    why_title: "Why you'll love the Recovery Studio",
    why: "Because getting stronger isn't only about how hard you train—it's also about how well you recover. Contrast therapy combines the relaxation of sauna heat with the invigorating experience of cold immersion, with potential benefits including support for muscle recovery, reduced post-workout soreness, relaxation, and better sleep. Our Recovery Studio makes it easy to build recovery into your routine, all in the same place you train.",
    kicker: "Train hard. Recover well. Stay strong for life."
  )
  Program.create!(
    key: "personal-training", name: "Personal Training", cta: "personal_training",
    blurb: "One-on-one sessions with a coach, built around your history, goals and schedule.",
    what_title: "What is personal training?",
    what: "Our personal training program pairs you with an expert coach for sessions tailored to your history, goals, and current ability. Whether you're new to CrossFit or a seasoned athlete aiming for a breakthrough, your plan is built around your needs. Flexible scheduling and private instruction deliver unmatched support for strength, health, and confidence.",
    why_title: "Why members love this program",
    why: "Clients rely on personal training for clear guidance, custom progressions, and the compassion only a dedicated coach provides. These sessions are especially helpful for beginners seeking foundational skills, busy adults needing flexibility, or those progressing through injury. Every win is noticed, every question answered. Personalized feedback, motivation, and results—the Valley Built way."
  )
end

if Step.none?
  [
    [ "Reach out", "Send us a note or call. We'll ask about your goals and answer whatever you're worried about." ],
    [ "Intro session", "Come see the gym, meet a coach, and talk through where you're starting from. No pressure, no sales pitch." ],
    [ "Learn the basics", "In The Build, coaches teach you the foundational movements and adjust every workout to your level." ],
    [ "Keep showing up", "This is where it gets good: the fitness compounds, and the people stop being strangers." ]
  ].each { |title, body| Step.create!(title:, body:) }
end

if MembershipOption.none?
  [
    [ "Unlimited", "Every class, every week, month to month." ],
    [ "Annual", "Paid in full up front at our best rate." ],
    [ "The Build", "Your first two months if you’re brand new to CrossFit." ],
    [ "Personal training", %(One-on-one sessions, on their own or alongside a membership. <a href="#programs">See the program</a>) ],
    [ "Drop-in pass", %($25 per class for out-of-town CrossFitters. <a href="#dropin">See drop-in details</a>) ],
    [ "Student", "Middle and high school athletes." ],
    [ "Family", "Discounted rates when more than one of you joins." ]
  ].each { |name, description| MembershipOption.create!(name:, description:) }
end

if StaffMember.none?
  StaffMember.create!(
    kind: "owner", name: "Jessica & Greg Isaacson", role: "Owners",
    certification: "CF-L2", certification_label: "Jessica coaches",
    bio: "[ short shared bio — the couple behind Valley Built: why they opened a gym in Grain Valley, what they want it to be for the town, and Greg's role alongside Jessica's coaching ]"
  )

  [
    [ "Chad Worman", "Head coach", "CF-L3", "his" ],
    [ "Chris Neske", "Coach", "CF-L1", "his" ],
    [ "Abby Harker", "Coach", "CF-L1", "her" ],
    [ "Chance Byrd", "Coach", "CF-L1", "his" ]
  ].each do |name, role, certification, pronoun|
    StaffMember.create!(kind: "coach", name:, role:, certification:, bio: "[ short bio — experience, what members can expect in #{pronoun} classes ]")
  end
end

if Faq.none?
  [
    [ "Do I need to be fit to start?", "No. That's what The Build is for. Every workout is scaled, and most people start with zero barbell experience." ],
    [ "How often should I come?", "Start with three days a week. Consistency beats intensity — in 30 days you'll already feel a difference." ],
    [ "Am I locked into a contract?", "Monthly memberships are month to month. The annual option is paid in full up front for a better rate." ],
    [ "Can my kid train here?", "Yes — we offer student rates for middle and high school athletes, and family memberships at a discount." ],
    [ "Can I drop in while I'm in town?", %(Absolutely — travelling athletes are welcome. A <a href="#dropin">drop-in pass</a> is $25 per class — reserve a class and show up ready to move. Questions? Email <a href="mailto:jessica@valleybuiltcrossfit.com">jessica@valleybuiltcrossfit.com</a>.) ]
  ].each { |question, answer| Faq.create!(question:, answer:) }
end

# Photos live on the server's disk, not in the database, so a new server starts
# with none. These ship in the repo and fill any slot that is still empty — a
# photo swapped out through the admin is never overwritten.
# A lookup that finds nothing used to attach nothing, quietly, and the gap only
# turned up by eye on the deployed site — so a miss raises instead.
attach = ->(record, name, file) do
  path = Rails.root.join("db/seed_images", file)
  raise "#{file} has no record to attach to" if record.nil?
  raise "db/seed_images/#{file} is missing" unless path.exist?

  slot = record.public_send(name)
  slot.attach(io: path.open, filename: file) unless slot.attached?
end

attach.(Site.instance, :hero_photo, "hero.webp")
{
  "crossfit" => "crossfit.webp",
  "recovery" => "recovery-studio.webp",
  "personal-training" => "personal-training.webp"
}.each { |key, file| attach.(Program.find_by(key:), :photo, file) }
{
  "Jessica & Greg Isaacson" => "jessica-greg-isaacson.jpg",
  "Chad Worman" => "chad-worman.jpg",
  "Chris Neske" => "chris-neske.jpg"
}.each { |name, file| attach.(StaffMember.find_by(name:), :photo, file) }

# Build the resized copies now, in the background, rather than making the first
# visitor wait while a dozen of them are generated at once.
WarmVariantsJob.perform_later

# Sample workouts from the design, for opening week — development only.
if Rails.env.development? && Workout.none?
  monday = Date.new(2026, 10, 5)
  [
    { workout_type: "For time", rx: "21-15-9 reps of:\nDeadlifts\nBox jumps\nPush presses", loads: "♀ 95-lb barbell • 20-in box\n♂ 135-lb barbell • 24-in box", score: "Post time to the whiteboard.", stimulus: "A short, fast triplet. Pick loads you could cycle for at least 10 reps unbroken when fresh. Most people should be done inside 10 minutes — if the deadlift is slowing you to singles, take weight off the bar.", intermediate: "15-12-9 reps.\n♀ 75-lb barbell • ♂ 115-lb barbell", beginner: "15-12-9 reps, box step-ups.\n♀ 45-lb barbell • ♂ 65-lb barbell" },
    { workout_type: "AMRAP 20", rx: "400-meter run\n15 wall-ball shots\n10 burpees", loads: "♀ 14-lb ball to 9 ft\n♂ 20-lb ball to 10 ft", score: "Post rounds and reps to the whiteboard.", stimulus: "A long, steady effort — pick a pace you can hold for all 20 minutes rather than sprinting the first round. Aim for 4–6 rounds. Break the wall balls early if you need to; the burpees are where the clock gets away from people.", intermediate: "300-meter run, 12 wall-ball shots.", beginner: "200-meter run, 9 wall-ball shots to a lower target, up-downs." },
    { name: "Service Cup Workout 3", workout_type: "Part A — on a 15-minute clock, for time", rx: "10 shuttle runs\n15 clean and jerks\n10 shuttle runs\n12 clean and jerks\n10 shuttle runs\n9 clean and jerks\n10 shuttle runs\n9 clean and jerks\n\nOne shuttle run is 25 feet down and 25 feet back.\n\nPart B — at 15 minutes, on a 3-minute clock:\nBuild to a 1-rep-max clean and jerk", loads: "♀ 95-lb barbell\n♂ 135-lb barbell", score: "Post your Part A time and heaviest lift to the whiteboard.", source: "Programmed from CrossFit.com — WOD 260916", stimulus: "Two parts, one barbell. Move through Part A at a pace that keeps you honest on the runs — the faster you finish, the more rest you get before the heavy single. Pick a moderate load you can cycle in quick sets rather than grind out one rep at a time. In Part B, build to a heavy clean and jerk while fatigued: two to four good lifts is plenty, and mechanics beat numbers every time.", intermediate: "Same structure.\n♀ 65-lb barbell • ♂ 95-lb barbell", beginner: "7 shuttle runs per round, same rep scheme.\n♀ 35-lb barbell • ♂ 45-lb barbell" },
    { workout_type: "3 rounds for time", rx: "500-meter row\n20 dumbbell snatches\n20 sit-ups", loads: "♀ 35-lb dumbbell\n♂ 50-lb dumbbell", score: "Post time to the whiteboard.", stimulus: "Middle-distance intervals with a pull-heavy bias. Hold a row pace you can repeat — negative splits are the goal. The dumbbell should be light enough for sets of 10.", intermediate: "400-meter row.\n♀ 20-lb dumbbell • ♂ 35-lb dumbbell", beginner: "300-meter row, 15 reps each.\n♀ 10-lb dumbbell • ♂ 20-lb dumbbell" },
    { name: "Benchmark Friday", workout_type: "For time", rx: "30 clean and jerks", loads: "♀ 95-lb barbell\n♂ 135-lb barbell", score: "Post time to the whiteboard. Compare to last time.", stimulus: "One movement, one barbell, nowhere to hide. Quick singles are usually faster than fighting for touch-and-go sets. Pick a load you can move every 5–8 seconds for the whole thing.", intermediate: "♀ 75-lb barbell • ♂ 105-lb barbell", beginner: "30 dumbbell clean and jerks.\n♀ 20-lb dumbbells • ♂ 35-lb dumbbells" },
    { name: "Partner WOD", workout_type: "With a partner, AMRAP 25", rx: "800-meter run together\nThen, splitting reps as needed:\n60 kettlebell swings\n40 push-ups\n20 pull-ups", loads: "♀ 35-lb kettlebell\n♂ 53-lb kettlebell", score: "Post rounds and reps to the whiteboard.", stimulus: "Saturday is the social one. Run together, then split the reps however works — one partner works while the other rests. Bring a friend; this one is built for it.", intermediate: "600-meter run, ring rows in place of pull-ups.", beginner: "400-meter run, 40 swings, 20 push-ups from the knees, 20 ring rows." },
    { name: "Rest Day", stimulus: "Recovery is part of the programming. Sleep, eat well, get outside — or come use the Recovery Studio." }
  ].each_with_index { |attrs, i| Workout.create!(attrs.merge(date: monday + i)) }
end

if Rails.env.development? && User.none?
  password = "Admin1!" # the shortest thing that satisfies User::PASSWORD_RULES
  User.create!(email_address: "admin@example.com", password:)
  puts "Created admin@example.com / #{password}"
end

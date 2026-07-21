# Idempotent seeds: safe to run repeatedly.

puts "Seeding settings..."
Setting.find_or_create_by!(key: "max_cv_file_size_mb") do |s|
  s.value = Setting::DEFAULT_MAX_CV_FILE_SIZE_MB.to_s
  s.value_type = "integer"
  s.description = "Maximum allowed CV upload size, in megabytes."
end

puts "Seeding job functions..."
# requires_big: BIG registration fields shown. revenue_based: average daily revenue shown.
job_functions = [
  { name: "General dentist",          slug: "general_dentist",          requires_big: true,  revenue: true },
  { name: "Dental hygienist",         slug: "dental_hygienist",         requires_big: true,  revenue: true },
  { name: "Dental assistant",         slug: "dental_assistant",         requires_big: false, revenue: false },
  { name: "Prevention assistant",     slug: "prevention_assistant",     requires_big: false, revenue: true },
  { name: "Paro-prevention assistant", slug: "paro_prevention_assistant", requires_big: false, revenue: true },
  { name: "Orthodontic assistant",    slug: "orthodontic_assistant",    requires_big: false, revenue: false },
  { name: "Front-office / receptionist", slug: "front_office",          requires_big: false, revenue: false },
  { name: "Practice manager",         slug: "practice_manager",         requires_big: false, revenue: false },
  { name: "Dental technician",        slug: "dental_technician",        requires_big: false, revenue: false },
  { name: "Specialist",               slug: "specialist",               requires_big: true,  revenue: true }
]

job_functions.each_with_index do |attrs, index|
  JobFunction.find_or_create_by!(slug: attrs[:slug]) do |fn|
    fn.name = attrs[:name]
    fn.requires_big_registration = attrs[:requires_big]
    fn.revenue_based = attrs[:revenue]
    fn.position = index
  end
end

puts "Seeding regions..."
regions = [
  "Noord-Holland", "Zuid-Holland", "Utrecht", "Noord-Brabant", "Gelderland",
  "Overijssel", "Limburg", "Groningen", "Friesland", "Drenthe", "Flevoland", "Zeeland"
]
regions.each_with_index do |name, index|
  Region.find_or_create_by!(name: name) { |r| r.position = index }
end

puts "Seeding employment types..."
employment_types = [
  { name: "Employed (permanent)", slug: "employed_permanent", category: "employed" },
  { name: "Employed (temporary)", slug: "employed_temporary", category: "employed" },
  { name: "Self-employed / freelance", slug: "self_employed", category: "self_employed" },
  { name: "Percentage-based", slug: "percentage_based", category: "self_employed" }
]
employment_types.each_with_index do |attrs, index|
  EmploymentType.find_or_create_by!(slug: attrs[:slug]) do |et|
    et.name = attrs[:name]
    et.category = attrs[:category]
    et.position = index
  end
end

puts "Seeding languages..."
languages = ["Dutch", "English", "German", "French", "Spanish", "Polish", "Turkish", "Arabic"]
languages.each_with_index do |name, index|
  Language.find_or_create_by!(name: name) { |l| l.position = index }
end

puts "Seeding skills by job function..."
skills_by_function = {
  "general_dentist" => ["Endodontics", "Restorative dentistry", "Pediatric dentistry", "Surgery", "Aligners"],
  "dental_hygienist" => ["Periodontology", "Prevention", "Scaling", "Patient education"],
  "dental_assistant" => ["Chairside assistance", "Sterilization", "Orthodontics", "Prevention"],
  "prevention_assistant" => ["Prevention", "Patient education", "Scaling"],
  "paro_prevention_assistant" => ["Periodontology", "Prevention", "Scaling"],
  "orthodontic_assistant" => ["Orthodontics", "Chairside assistance", "Patient communication"],
  "front_office" => ["Planning", "Phone handling", "Invoicing", "Patient communication"],
  "practice_manager" => ["Team management", "Scheduling", "HR", "Practice operations"],
  "dental_technician" => ["Prosthetics", "CAD/CAM", "Crown and bridge work"],
  "specialist" => ["Endodontics", "Surgery", "Orthodontics", "Periodontology"]
}
skills_by_function.each do |slug, names|
  fn = JobFunction.find_by!(slug: slug)
  names.each_with_index do |name, index|
    Skill.find_or_create_by!(job_function: fn, name: name) { |s| s.position = index }
  end
end

if Rails.env.development?
  puts "Seeding admin user..."
  AdminUser.find_or_create_by!(email: "admin@example.com") do |admin|
    admin.password = "password"
    admin.password_confirmation = "password"
  end

  puts "Seeding demo candidate..."
  demo = User.find_or_create_by!(email: "candidate@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
  end
  demo.candidate_profile! # ensure an (empty) profile exists

  puts "\nSeed complete."
  puts "  Admin:     admin@example.com / password       (/admin)"
  puts "  Candidate: candidate@example.com / password"
end

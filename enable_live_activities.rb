require 'xcodeproj'
project_path = 'LibraryApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

found = false
project.targets.each do |target|
  # Match the main app target
  if target.name == 'LibraryApp'
    found = true
    target.build_configurations.each do |config|
      config.build_settings['INFOPLIST_KEY_NSSupportsLiveActivities'] = 'YES'
    end
  end
end

if found
  project.save
  puts "Successfully enabled NSSupportsLiveActivities in LibraryApp.xcodeproj"
else
  puts "Could not find target named 'LibraryApp'"
end

require 'xcodeproj'
project_path = 'LibraryApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['INFOPLIST_KEY_NSCameraUsageDescription'] = 'We need camera access to scan books for reading information.'
  end
end
project.save

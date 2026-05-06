require 'xcodeproj'

project_path = "LibraryApp.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Skip GoogleService-Info.plist since it's inside a PBXFileSystemSynchronizedRootGroup in Xcode 16!

# Ensure Swift Package Dependency exists manually
framework_phase = target.frameworks_build_phase
packages = project.root_object.package_references

has_firebase = packages.any? { |pkg| pkg.repositoryURL == "https://github.com/firebase/firebase-ios-sdk" }
unless has_firebase
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = "https://github.com/firebase/firebase-ios-sdk"
  package_ref.requirement = { "kind" => "upToNextMajorVersion", "minimumVersion" => "11.0.0" }
  project.root_object.package_references << package_ref

  auth_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  auth_dep.product_name = "FirebaseAuth"
  auth_dep.package = package_ref
  target.package_product_dependencies << auth_dep

  firestore_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  firestore_dep.product_name = "FirebaseFirestore"
  firestore_dep.package = package_ref
  target.package_product_dependencies << firestore_dep

  # Ensure the product build files are generated
  auth_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  auth_build_file.product_ref = auth_dep
  framework_phase.files << auth_build_file

  firestore_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  firestore_build_file.product_ref = firestore_dep
  framework_phase.files << firestore_build_file

  puts "Injected Firebase iOS SDK successfully!"
else
  puts "Firebase SDK already injected!"
end

project.save
puts "Project formally saved."

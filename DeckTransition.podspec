Pod::Spec.new do |s|
  s.name         = "DeckTransition"
  s.version      = "0.3.0"
  s.summary      = ""
  spec.description      = <<-DESC
              DeckTransition is an attempt to recreate the iOS 10 Apple Music now playing and iMessage App Store transition.
              DESC
  s.homepage     = "https://github.com/HarshilShah/DeckTransition"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Harshil Shah" => "harshilshah1910@me.com" }
  s.social_media_url   = "https://twitter.com/harshilshah1910"
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/HarshilShah/DeckTransition.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "UIKit"
end
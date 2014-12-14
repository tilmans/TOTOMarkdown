#
# Be sure to run `pod lib lint TOTOMarkdown.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TOTOMarkdown"
  s.version          = "0.1.0"
  s.summary          = "A markdown parser for Cocoa"
  s.description      = <<-DESC
                        A pure Cocoa implementation of Markdown that tries to support
                        all of the common functionality.
                        DESC
  s.homepage         = "https://github.com/tilmans/TOTOMarkdown"
  s.license          = 'MIT'
  s.author           = { "Tilman Schlenker" => "tilman@mailbox.org" }
  s.source           = { :git => "https://github.com/tilmans/TOTOMarkdown.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'TOTOMarkdown' => ['Pod/Assets/*.png']
  }
end

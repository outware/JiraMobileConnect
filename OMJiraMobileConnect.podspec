Pod::Spec.new do |s|
  s.name         = "OMJiraMobileConnect"
  s.version      = "1.0.0"
  s.license      = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.summary      = "Jira Mobile Connect library"
  s.homepage     = "https://bitbucket.org/atlassian/jiraconnect-ios"
  s.author       = { "Atlassian Software" => "info@atlassian.com" }
  s.source       = { :git => "git@github.com:outware-mobile/OMJiraMobileConnect.git", :tag => "v#{s.version}" }
  s.platform     = :ios
  s.source_files = '*.{h,m}'
  s.prefix_header_file = "OMCommonBase/OMCommonBase_Prefix.pch"

  s.frameworks = 'Foundation', 'UIKit', 'CoreGraphics', 'CFNetwork', 'SystemConfiguration', 'MobileCoreServices', 'CoreGraphics', 'AVFoundation', 'CoreLocation', 'libsqlite3'

end

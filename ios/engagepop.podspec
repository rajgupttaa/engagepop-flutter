Pod::Spec.new do |s|
  s.name             = 'engagepop'
  s.version          = '0.2.3'
  s.summary          = 'EngagePop Flutter SDK — native push and in-app messages.'
  s.homepage         = 'https://engagepop.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'EngagePop' => 'support@engagepop.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'

  s.dependency 'Flutter'
  # The native iOS SDK does the real work.
  s.dependency 'EngagePop'
end

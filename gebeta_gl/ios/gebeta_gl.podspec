#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'gebeta_gl'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Gebeta' => 'info@gebeta.app' }
  s.source           = { :path => '.' }
  s.source_files = 'gebeta_gl/Sources/gebeta_gl/**/*'
  s.dependency 'Flutter'
  # When updating the dependency version,
  # make sure to also update the version in Package.swift.
  s.dependency 'MapLibre', '6.5.0'
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'
end


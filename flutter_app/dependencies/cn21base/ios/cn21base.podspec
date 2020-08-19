#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'cn21base'
  s.version          = '0.0.1'
  s.summary          = 'Base and common utilities project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://www.21cn.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '21cn' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.swift_version    = '4.0'

  s.ios.deployment_target = '10.0'
end


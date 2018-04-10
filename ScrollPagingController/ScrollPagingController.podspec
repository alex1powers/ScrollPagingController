#
# Be sure to run `pod lib lint ScrollPagingController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ScrollPagingController'
  s.version          = '0.0.1'
  s.summary          = 'ScrollPagingController'
  s.homepage         = "local" #path to home page
  s.license          = { type: 'MIT License (Expat)', text: '2018 © Alexander Goremykin. All rights reserved.' }
  s.authors          = { 'Alexander Goremykin' => 'sanllier@yandex-team.ru' }
  s.source           = { :git => 'local', :tag => s.version.to_s }
  s.description      = 'ScrollPagingController - controller for implementing custom paging bahavior for UIScrollView'
  s.ios.deployment_target = '8.0'
  s.source_files     = 'Sources/*'
  s.requires_arc     = true
end

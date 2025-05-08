# Be sure to run `pod lib lint DoraemonKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DoKit'
  s.version          = '4.0.0'
  s.summary          = '自行维护 DoraemonKit(DoKit) 的 iOS 部分'
  s.description      = <<-DESC
自行维护 DoraemonKit(DoKit) 的 iOS 部分，致力于回归工具初心
                       DESC

  s.homepage         = 'https://darkthanblack.github.io'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'OrangeLab' => 'orange-lab@didiglobal.com' }
  s.source           = { :git => 'https://github.com/darkThanBlack/DoKit-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.default_subspec = 'Core'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
  
  s.subspec 'CFoundation' do |ss|
    ss.source_files = 'iOS/DoKit/Classes/CFoundation/*.{h,c}'
    ss.compiler_flags = '-Wall', '-Wextra', '-Wpedantic', '-Werror', '-fvisibility=hidden'
  end
  
  s.subspec 'Foundation' do |ss|
    ss.source_files = 'iOS/DoKit/Classes/Foundation/**/*.{h,m}'
    # language-extension-token warning be used to implement Objective-C typeof().
    # ?: grammar
    ss.compiler_flags = '-Wall', '-Wextra', '-Werror'
    ss.dependency 'SocketRocket', '~> 0.6'
    ss.dependency 'Mantle', '~> 2.2'
  end
  
#  s.subspec 'CoreNG' do |ss|
#    ss.dependency 'DoKit/Foundation'
#    ss.source_files = 'iOS/DoKit/Classes/Core/**/*.{h,m}'
#    # language-extension-token warning be used to implement Objective-C typeof().
#    # ?: grammar
#    ss.compiler_flags = '-Wall', '-Wextra', '-Wpedantic', '-Werror', '-Wno-language-extension-token', '-Wno-gnu-conditional-omitted-operand'
#    ss.resource_bundle = {
#      'DoKitResource' => [
#        'iOS/DoKit/Assets/Assets.xcassets',
#        'iOS/DoKit/Assets/*.xib'
#      ]
#    }
#    ss.dependency 'SocketRocket', '~> 0.6'
#    ss.dependency 'Mantle', '~> 2.2'
#  end

  s.subspec 'EventSynthesize' do |ss|
    ss.source_files = 'iOS/DoKit/Classes/EventSynthesize/*.{h,m}'
    ss.compiler_flags = '-Wall', '-Wextra', '-Wpedantic', '-Werror', '-fvisibility=hidden', '-Wno-gnu-conditional-omitted-operand', '-Wno-pointer-arith'
    ss.framework = 'IOKit'
    ss.dependency 'DoKit/Foundation'
  end

  s.subspec 'Core' do |ss| 
    ss.source_files = 'iOS/DoraemonKit/Src/Core/**/*.{h,m,c,mm}'
    ss.resource_bundle = {
      'DoraemonKit' => 'iOS/DoraemonKit/Resource/**/*'
    }
  end
  
  s.subspec 'DiDi' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/DiDi/**/*.{h,m,c,mm}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithDiDi'
    }
    
    ss.dependency 'DoKit/Core'
    ss.dependency 'GCDWebServer'
    ss.dependency 'GCDWebServer/WebUploader'
    ss.dependency 'GCDWebServer/WebDAV'
    ss.dependency 'FMDB'
  end

  s.subspec 'Logger' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/Logger/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithLogger'
    }
    ss.dependency 'DoKit/Core'
    ss.dependency 'CocoaLumberjack'
  end

  s.subspec 'GPS' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/GPS/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithGPS'
    }
    ss.dependency 'DoKit/Core'
  end

  s.subspec 'Load' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/MethodUseTime/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithLoad'
    }
    ss.dependency 'DoKit/Core'
    # https://guides.cocoapods.org/syntax/podspec.html#vendored_frameworks
    # TODO(ChasonTang): Should change to vendored_framework?
    ss.vendored_frameworks = 'iOS/DoraemonKit/Framework/*.framework'
  end

  s.subspec 'Weex' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/Weex/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithWeex'
    }
    ss.dependency 'DoKit/Core'
    ss.dependency 'WeexSDK'
    ss.dependency 'WXDevtool'
  end

  s.subspec 'Database' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/Database/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithDatabase'
    }
    ss.dependency 'DoKit/Core'
    ss.dependency 'YYDebugDatabase'
  end

  s.subspec 'MLeaksFinder' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/MLeaksFinder/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithMLeaksFinder'
    }
    ss.dependency 'DoKit/Core'
    ss.dependency 'FBRetainCycleDetector'
  end

  s.subspec 'MultiControl' do |ss|
    ss.source_files = 'iOS/DoraemonKit/Src/MultiControl/**/*{.h,.m}'
    ss.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) DoraemonWithMultiControl'
    }
    ss.dependency 'DoKit/Core'
    ss.dependency 'DoKit/Foundation'
  end
end

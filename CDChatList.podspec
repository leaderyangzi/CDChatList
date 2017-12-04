

Pod::Spec.new do |s|
  s.name             = 'CDChatList'
  s.version          = '0.1.0'
  s.summary          = '聊天界面的封装.'

  s.description      = <<-DESC
    ios 版本对聊天界面的封装
                       DESC
  s.homepage         = 'http://git-ma.paic.com.cn/aat_component_ios/ChatList'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'chdo002' => '1107661983@qq.com' }
  s.source           = { :git => 'http://git-ma.paic.com.cn/aat/ChatList.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CDChatList/Classes/**/*'
  
  s.resource_bundles = {
     'CDChatList' => ['CDChatList/Assets/*.png']
  }

  s.public_header_files = 'CDChatList/Classes/**/**/*.h'

  s.frameworks = 'UIKit'

  s.dependency 'SDWebImage'
  s.dependency 'YYText'

end

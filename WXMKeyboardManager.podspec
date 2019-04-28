Pod::Spec.new do |s|
  s.name         = "WXMKeyboardManager" 
  s.version      = "0.0.1"        
  s.license      = "MIT"
  s.summary      = "键盘自动收起"

  s.homepage     = "https://github.com/XiaoMing-Wang/WXMKeyboardManager" 
  s.source       = { :git => "https://github.com/XiaoMing-Wang/WXMKeyboardManager.git", :tag => "#{s.version}" }
  s.source_files = "WXMKeyboardManager/Classes/**/*"
  s.requires_arc = true 
  s.platform     = :ios, "9.0" 
  # s.frameworks   = "UIKit", "Foundation" 
  # s.dependency   = "AFNetworking" 
  s.author             = { "wq" => "347511109@qq.com" } 
end
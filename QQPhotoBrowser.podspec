Pod::Spec.new do |s|
  s.name          = "QQPhotoBrowser"
  s.version       = "1.0.0"
  s.summary       = "Photo Browser."
  s.homepage      = "https://github.com/MidPush/QQPhotoBrowser"
  s.license       = "MIT"
  s.author        = { "xz" => "497569855@qq.com" }
  s.platform      = :ios, '9.0'
  s.source        = { :git => "https://github.com/MidPush/QQPhotoBrowser.git", :tag => s.version }
  s.source_files  = "QQPhotoBrowser/*.{h,m}"
  s.requires_arc  = true
  s.dependency 'SDWebImage', '>= 5.0.0'
end

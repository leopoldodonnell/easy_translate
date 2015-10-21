require File.dirname(__FILE__) + '/lib/easy_translate/version'

spec = Gem::Specification.new do |s|
  s.name = 'easy_translate'  
  s.author = 'John Crepezzi'
  s.add_development_dependency('rspec')
  s.add_dependency('json')
  s.description = 'easy_translate is a wrapper for the google translate API that makes sense programatically, and implements API keys'
  s.email = 'john.crepezzi@gmail.com'
  s.files = Dir['lib/**/*.rb']
  s.has_rdoc = true
  s.homepage = 'https://github.com/seejohnrun/easy_translate'
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.summary = 'Google Translate API Wrapper for Ruby'
  s.test_files = Dir.glob('spec/*.rb')
  s.bindir        = "bin"
  s.executables   = ['easy-translate']
  s.version = EasyTranslate::VERSION
end

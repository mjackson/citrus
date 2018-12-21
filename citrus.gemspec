$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'citrus/version'

Gem::Specification.new do |s|
  s.name = 'citrus'
  s.version = Citrus.version
  s.date = Time.now.strftime('%Y-%m-%d')

  s.summary = 'Parsing Expressions for Ruby'
  s.description = 'Parsing Expressions for Ruby'

  s.author = 'Michael Jackson'
  s.email = 'mjijackson@gmail.com'

  s.require_paths = %w< lib >

  s.files = Dir['benchmark/**'] +
    Dir['doc/**'] +
    Dir['extras/**'] +
    Dir['lib/**/*.rb'] +
    Dir['test/**/*'] +
    %w< citrus.gemspec Rakefile README.md CHANGES >

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/ }

  s.add_development_dependency('rake')

  s.rdoc_options = %w< --line-numbers --inline-source --title Citrus --main Citrus >
  s.extra_rdoc_files = %w< README.md CHANGES >

  s.homepage = 'http://mjackson.github.io/citrus'
  s.licenses = ['MIT']
end

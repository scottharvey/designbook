require_relative "lib/designbook/version"

Gem::Specification.new do |spec|
  spec.name        = "designbook"
  spec.version     = Designbook::VERSION
  spec.authors     = [ "Scott Harvey" ]
  spec.email       = [ "hello@example.com" ]
  spec.homepage    = "https://github.com/scottharvey/designbook"
  spec.summary     = "Rails engine for markdown-first design documentation."
  spec.description = "Designbook is a mountable Rails engine for writing and browsing design system documentation alongside live component previews."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "commonmarker"
  spec.add_dependency "lookbook"
  spec.add_dependency "rouge"
end

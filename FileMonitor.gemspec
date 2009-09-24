(in /Users/joshaven/projects/FileMonitor)
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{filemonitor}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshaven Potter"]
  s.date = %q{2009-09-24}
  s.description = %q{Watches the file system for changes.}
  s.email = ["yourtech@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.markdown", "Rakefile", "lib/FileMonitor.rb", "lib/FileMonitor/store.rb", "script/console", "script/destroy", "script/generate", "spec/FileMonitor_spec.rb", "spec/MonitoredItem_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/rspec.rake"]
  s.homepage = %q{http://github.com/joshaven/FileMonitor}
  s.rdoc_options = ["--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{filemonitor}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Watches the file system for changes.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 2.3.3"])
    else
      s.add_dependency(%q<hoe>, [">= 2.3.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 2.3.3"])
  end
end

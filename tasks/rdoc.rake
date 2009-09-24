require 'rake/rdoctask'
require 'rdiscount'

Rake::RDocTask.new('rdoc') do |t|
  t.rdoc_files.include('README.markdown', 'lib/**/*.rb')
  t.main = 'README.markdown'
  t.title = "FileMonitor API Documentation"
  t.rdoc_dir = 'doc'
end
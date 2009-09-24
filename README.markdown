# FileMonitor
Calls a Proc when a watched file is changed.

* Documentation:   http://filemonitor.rubyforge.org/rdoc
* Code Repository: http://github.com/joshaven/FileMonitor
* Joshaven Potter: yourtech@gmail.com

## Notice
This project has only been tested on posix compatible systems, sorry for you windows users.  If you get this
to run under windows, let me know and I'll release a windows compatible version.

## Installation
    gem install filemonitor  # you may need to run:  sudo gem install filemonitor

## Examples
In the following examples, the block passed will be executed when the file changes.  These examples only 
echo strings but I am sure you'll find something more useful to do in the callback proc.

    require 'filemonitor'
    
    # Example 1: Generate a FileMonitor subprocess with one command:
    fm = FileMonitor.when_modified(Dir.pwd, "/path/to/other/file.rb") do |watched_item| 
      puts "Change detected in #{watched_item.path} "
    end
    
    # thats it... if you want to stop the subprocess, issue:   fm.stop
    
    # Example 2: Generate a manually run FileMonitor:
    file_spy = FileMonitor.new {|f| puts "Default proc called because #{f.path} changed."}
    file_spy.add(Dir.pwd) do |f|
      puts "Monitored Item's proc called because #{f.path} changed."
    end
    
    file_spy.process   # This will look for changes one time... call this again when you want to find changes.
    # if you want to launch a background process then do file_spy.spawn or its alias: file_spy.start

### Context Examples
Both the FileMonitor.new method and a FileMonitor instance fm.add method can accept a block with 0 to 2 arities.
See Also the api docs: <http://filemonitor.rubyforge.org/rdoc>

This block is working in the context in which it was created:

    changes = false
    fm.add(Dir.pwd) {changes = true}  # The 'changes' variable will be set to true when a change is detected
    fm.process
    respond_to_file_changes if changes
    
This block is working in the context created and is aware of the watched file instance 'f'.  The watched file will 
respond to :path, :callback, & :digest and is an instance of: MonitoredItems::Store

    changed_ruby_files = []
    fm.add(Dir.pwd, /\.rb$/) do |f|     # Adds all .rb files recursively starting with the working directory
      changed_ruby_files << f.path      # The changed_ruby_files will contain the path of the changed files. 
    end
    fm.process
    handel_changes(changed_ruby_files)  # Do somehting with the changed files
    changed_ruby_files = []             # Cleanup changes so the array doesn't keep growing
    
    
This block is working in the context created and is aware of the watched_file instance 'f' as well as the 
file_monitor instance 'fm'.  The fm object can be acted on within the block the same way it is outside the block, 
an example use of this may be to add all files in a folder when a file is changed...

    fm.add(Dir.pwd) do |f, fm| 
      fm.add(APP_ROOT) if f.path == (APP_ROOT + Manifest.txt)   # Start watching any new files when added to to the manifest.txt file.
    end

## License
(The MIT License)

Copyright (c) 2009 Joshaven Potter

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
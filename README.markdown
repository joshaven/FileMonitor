# FileMonitor
* http://github.com/joshaven/FileMonitor
* Joshaven Potter: <yourtech@gmail.com>


## DESCRIPTION

Watches the file system for changes.  

## Notice
This project has only been tested on posix compatible systems, sorry for
you windows users.  If you get this to run under windows, let me know and I'll release a windows compatible version.

## Usage
    require 'filemonitor'
    file_spy = FileMonitor.new
    # Add one or more files or directories with a callback block
    file_spy.add(Dir.pwd) do |i|
      # This callback will be executed in the context of a single file, even if you added a directory
      puts "you probably should handle the change in #{i.file}"
    end
    # run a background process that watches for changed files... which is cloesed along with the parent process.
    file_spy.spawn 
    

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
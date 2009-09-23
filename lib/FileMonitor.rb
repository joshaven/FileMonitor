require File.dirname(__FILE__) + '/FileMonitor/store'
require 'find' # needed for the :files_recursive method

# Purpose:
# Watches the file system for changes
#
# Usage:
#
#   require 'filemonitor'
#
#   # Create a FileMonitor instance and assign the callback to the entire object.
#   # In the following example, "watched_item" is a MonitoredItems::Store, see the new
#   # method for a better example of working in your block.
#   file_spy = FileMonitor.new do |watched_item| ... end
#
#   # Any files in the working directory (Dir.pwd) and its sub-directories will
#   #  be watched for changes.  If a change is found the callback assigned above 
#   #  will be enacted.
#   file_spy << Dir.pwd
#   file_spy << "/path/to/other/file.rb"
#
#   # launch an independent process to do the monitoring:
#   file_spy.spawn
#
#   # Alternatively you can do all of the above in one line:
#   FileMonitor.when_modified(Dir.pwd, "/path/to/other/file.rb") do |watched_item| ... end
class FileMonitor
  VERSION = '0.0.2'
  # The new method may be called with an optional callback which must be a block 
  # either do...end or {...}.
  # The block may consiste of upto arguments ie {|watched_item, monitored|}, in which case, the
  # watched_item is an instance of FileMonitor::Store and monitored is the FileMonitor instances self.
  #
  # The first argument of the block, 'watched_item' in this case, will respond to: (:path, :modified & :callback).
  # The second argument of the block, 'monitored' in this case, will respond any FileMonitor method.
  # 
  # Example:
  #   FileMonitor.new do |watched_item|
  #     puts "I am watching this file: #{watched_item.path}"
  #     puts "When I find a change I will call watched_item.callback"
  #   end
  #
  #   FileMonitor.new do |watched_item, monitored|
  #
  #     # add files from a file that is a list of files to watch... Note: There
  #     IO.readlines(watched_item.path).each {|file| monitored << file } if watched_item.path == '/path/to/file/watchme.list'
  #
  #     # clear watchme.list so we won't add all watch files every time the file changes
  #     open(watched_item) { |f| puts '' }
  #   end
  def initialize(&callback)
    @watched = []
  end
  
  # Returns the process id of a FileMonitor which is watching the given paths.  The process automatically
  # calls the given callback when changes are found.
  #
  # Example:
  #   fm = FileMonitor.when_modified(Dir.pwd, "/path/to/other/file.rb") do |watched_item| ... end   #=> 12980
  def self.when_modified(*paths, &callback)
    fm = FileMonitor.new &callback
    paths.each {|path| fm << path}
    return fm
  end
  
  # Stops a spawned FileMonitor instance.  The FileMonitor will finish the the currnet iteration and exit gracefully.
  def stop()
    # command, pid, ppid = `ps -p #{process_id} -o "comm pid ppid"|grep #{process_id}`.split
    # Process.kill('INT', process_id) if Process.pid == ppid # kill only if My process is the Parent process
    
    # Send user defined signal USR1 to process.  This is trapped in spauned processes and tells the process to Ctrl+C
    # The user defined signial is sent as a safty percausion because the process id is not tracked through a pid file
    # nor compared with the running command.  The FileMonitor spaun will respond to the USR1 signal by exiting properly.*
    if Fixnum === @spawns
      Process.kill('USR1', @spawns)
      Process.wait @spawns
    end
  end
  
  # Halts a spawned FileMonitor Instance.  The current iteration will be halted in its tracks.
  def halt()
    if Fixnum === @spawns
      Process.kill('USR2', @spawns)
      Process.wait @spawns
    end
  end

  # The add method accepts a directory path or file path and optional callback.  If a directory path is given all files in that 
  # path are recursively added.  If a callback is given then that proc will be called when a change is detected on that file or 
  # group of files.  If no proc is given via the add method then the object callback is called.
  #
  # Example:
  #   fm = FileMonitor.new do |path|
  #     puts "Detected a change on #{path}"
  #   end
  #
  #   # The following will run the default callback when changes are found in the /tmp folder:
  #   fm.add '/tmp'
  #
  #   # The following will run its own callback on changed files in the /home folder:
  #   fm.add '/home' do |path|
  #     puts "A users file has changed: #{path}"
  #   end
  def add(path, &callback)
    if File.file? path
      i = MonitoredItems::Store.new
      i.path      File.expand_path(path)
      i.callback  callback
      index = index_of(path) || @watched.size
      @watched[index] = i
      # @watched << MonitoredItems::Store.new({:file => File.expand_path(path), :callback => callback})
      return true
    elsif File.directory? path
      files_recursive(path).each {|f| self << f &callback }
      return true
    end
    false
  end
  
  # The '<<' method works the same way as the 'add' method but does not support a callback.
  #
  # Example:
  #   fm = FileMonitor.new do |path|
  #     puts "Detected a change on #{path}"
  #   end
  #
  #   # The following will run the default callback when changes are found in the /tmp folder:
  #   fm << '/tmp'
  def <<(path)
    add path
  end
  
  # def changes?
  #   return first_changed
  # end

  # Itterates watched files and runs callbacks when changes are detected.
  def process
    @watched.each do |i|
      key = digest(i.path)
      i.digest key if i.digest.nil?  # skip first change detection, its always unknown on first run
      respond_to_change(i, key) unless i.digest == key
    end
  end

  # Returns an Array of files being watched.  Each instance is a MonitoredItems::Store Object
  def watching
    @watched
  end

  def monitor(interval = 1)
    trap("INT") do 
      STDERR.puts "  FileMonitor was interrupted by Control-C"
      exit
    end
    
    trap("USR1") do
      STDERR.puts "  FileMonitor was asked nicely to stop."
      @stop = true
      @spawns = nil
    end

    trap("USR2") do
      STDERR.puts "  FileMonitor was halted."
      @spawns = nil
      exit
    end

    
    while true
      exit if @stop
      process
      sleep interval unless @stop
    end
  end
  
  # Returns index of watching item or false if non existant.
  def index_of(path)
    watching.each_with_index {|watched,i| return i if watched.path == path}
    false
  end

  # Spauns a child process that is looking for changes at every given interval.  
  # The interval is in seconds and defaults to 1 second.
  def spawn(interval = 1)
    if @spawns.nil? 
      @spawns = fork {monitor interval}
      Process.detach(@spawns)
      
      Kernel.at_exit do
        Process.kill('HUP', @spawns) unless `ps -p #{@spawns}|grep ^[0-9]`.split().empty?
        @spawns = nil
      end
      @spawns
    else
      @spawns
    end
  end
  
  
private
  attr_accessor :spawns, :callback
  # Call callback and update digest with given key.
  def respond_to_change(item, key)
    if Proc === item.callback     # Use watched instance callback if possible.
      call item.callback, item, self, key
    elsif Proc === self.callback  # Use object level callback if possible.
      call self.callback, item, self, key
    end
    item.digest = key
  end
  
  # Calls a proc with no more then the needed arguments.  This avoids an error when
  # calling a proc with two arguments when the proc only handels one argument.
  def call(proc, *args)
    proc.call(args[0..(proc.arity-1)])
  end

  # Itterates through watched items and returns the first changed or false if no changes are found.
  # def first_changed
  #   # returns first changed item or false
  #   @watched.each {|i| return i if changed? i}
  #   false
  # end
 
  # Returns new digest if changed or false if unchanged.
  def changed?(item)
    d = digest(item.path)         # get current digets
    d == item.digest ? false : d  # return new digest or false if unchanged
  end

  # Returns a string representation of the file state.
  def digest(file)
    File.mtime(file)
  end

  # Returns an array of all files in dirname recursively.  Accepts an optional file name regexp filter.
  # The following will find files ending in ".rb" recursively beginning in the working dir:
  #   files_recursive Dir.pwd, /\.rb$/
  def files_recursive(dirname, file_name_regexp=/.*/)
    paths = []
    
    Find.find(dirname) do |path|
      if FileTest.directory?(path)
        Find.prune if File.basename(path)[0] == ?. # Don't look any further into directies beginning with a dot.
      else
        paths << path if file_name_regexp === path # Amend the return array if the file found matches the regexp
      end
    end
    
    return paths
  end
end
require ::File.dirname(__FILE__) + '/FileMonitor/store'
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
  VERSION = '0.0.4'
  attr_accessor :callback, :pid, :watched
  # The new method may be called with an optional callback which must be a block 
  # either do...end or {...}.
  # The block may consist of upto two arguments ie {|watched_item, monitored|}, in which case, the
  # watched_item is an instance of FileMonitor::Store and monitored is the FileMonitor instances self.
  #
  # The first argument of the block, 'watched_item' in this case, will respond to: (:path, :modified & :callback).
  # The second argument of the block, 'monitored' in this case, will respond any FileMonitor method.
  # 
  # Example:
  #   FileMonitor.new do |watched_item|
  #     puts "My file name & path is: #{watched_item.path}"
  #     puts "When I find a change I will call watched_item.callback which displays this text."
  #   end
  #
  #   FileMonitor.new do |watched_item, monitored|
  #     # Add files from a file that is a list of files to watch... Note: There
  #     IO.readlines(watched_item.path).each {|file| monitored << file } if watched_item.path == '/path/to/file/watchme.list'
  #     # Clear watchme.list so we won't add all watch files every time the file changes
  #     open(watched_item) { |f| puts "This is the callback that is run..." }
  #   end
  def initialize(options={}, &callback)
    @options=options
    # @options[:persistent] ||= false
    @watched = []
    @callback = callback unless callback.nil?
    @options[:rescan_directories] ||= true
  end
  
  # Returns a spawned FileMonitor instance.  The independent process automatically calls the given
  # callback when changes are found.
  #
  # Example:
  #   fm = FileMonitor.when_modified(Dir.pwd, "/path/to/other/file.rb") {|watched_item, file_monitor| ... }
  #   fm.pid            # => 23994
  #   fm.callback.nil?  # => false
  #   fm.watched.size   # => 28
  def self.when_modified(*paths, &callback)
    fm = FileMonitor.new &callback
    paths.each {|path| fm << path}
    fm.spawn
    return fm
  end
  
  # The add method accepts a directory path or file path and optional callback.  If a directory path is given all files in that 
  # path are recursively added.  If a callback is given then that proc will be called when a change is detected on that file or 
  # group of files.  If no proc is given via the add method then the object callback is called.  If a regexp is given as the 
  # second argument only files matching the regexp will be monitored.
  #
  # Example:
  #   fm = FileMonitor.new do |path|
  #     puts "Detected a change on #{path}"
  #   end
  #
  #   # The following will run the default callback when changes are found in the /tmp folder:
  #   fm.add '/tmp'
  #
  #   # The following will run the given callback on any files ending in 'txt' in the /home folder when changed:
  #   fm.add('/home', /txt$/) do |path|
  #     puts "A users file has changed: #{path}"
  #   end
  def add(path, regexp_file_filter=/.*/, &callback)
    # path = ::File.expand_path(path)
    if ::File.file?(path) && regexp_file_filter === ::File.split(path).last
      # Bail out if the file is already being watched.
      return true if index_of(path) 
      index = @watched.size
      @watched[index] = MonitoredItems::Store.new({:path=>::File.expand_path(path), :callback=>callback, :digest=>digest(path)})
      return true
    elsif ::File.directory? path
      files_recursive(path).each {|f| add(f, regexp_file_filter, &callback) }
      return true
    else
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
  def <<(path, regexp_file_filter=/.*/)
    add path, regexp_file_filter
  end

  # Itterates watched files and runs callbacks when changes are detected.  This is the semi-automatic way to run the FileMonitor.
  #
  # Example:
  #   changed_files = []
  #   fm = FileMonitor.new() {|watched_item| changed_files = watched_item.path}
  #   fm << '/tmp'
  #   fm.process   # this will look for changes in any watched items only once... call this when you want to look for changes.
  def process
    scan_directories if @options[:rescan_directories]

    @watched.each do |i|
      # Unless the persistant option is set, this will remove watched file if it has been removed
      # if the file still exists then it will be processed regardless of the persistent option.
      unless @options[:persistent] || ::File.exists?(i.path) 
        @watched.delete(i)
      else
        key = digest(i.path)
        # i.digest =  key if i.digest.nil?  # skip first change detection, its always unknown on first run
      
        unless i.digest == key
          respond_to_change(i, key) 
        end
      end
    end
  end

  # Runs an endless loop watching for changes.  It will sleep for the given interval between looking for changes.  This method
  # is intended to be run in a subprocess or threaded environment.  The spawn method calls this method and takes care of
  # the forking and pid management for you.
  #
  # Example:
  #   fm = FileMonitor.new
  #   fm << '/tmp'
  #   fm.monitor
  #   puts "will not get here unless a signal is sent to the process which interrupts the loop."
  def monitor(interval = 1)
    trap("INT") do 
      puts "  FileMonitor was interrupted by Control-C... exiting gracefully"
      # exit
      @shutdown = true
    end
    
    trap("USR1") do
      puts "  FileMonitor was asked nicely to stop."
      @shutdown = true
      pid = nil
    end

    trap("USR2") do
      puts "  FileMonitor was halted."
      pid = nil
      exit
    end

    
    while true
      exit if @shutdown
      process
      sleep interval unless @shutdown
    end
  end

  # Returns index of watched item or false if non existant.
  #
  # Example:
  #  fm = FileMonitor.new
  #  fm << '/tmp/first.txt'
  #  fm << '/tmp/second.txt'
  #  fm.index_of '/tmp/first.txt'   # => 0
  #  fm.index_of '/tmp/first.txt'   # => 1
  #  fm.index_of '/tmp/woops.txt'   # => false
  def index_of(path)
    watched.each_with_index {|watched,i| return i if watched.path == path}
    false
  end

  # Spauns a child process that is looking for changes at every given interval.  
  # The interval is in seconds and defaults to 1 second.
  #
  # Example:
  #   fm = FileMonitor.new {|watched_item| puts 'do something when file is changed'}
  #   fm << @app_root + '/lib'
  #   fm.spawn        # and now its doing its job... 
  def spawn(interval = 1)
    if @pid.nil? 
      @pid = fork {monitor interval}
      Process.detach(pid)
      
      Kernel.at_exit do
        # sends the kill command unless the pid is not found on the system
        Process.kill('HUP', @pid) if process_running?
        @pid = nil
      end
    end
    @pid
  end
  alias_method :start, :spawn
  # Stops a spawned FileMonitor instance.  The FileMonitor will finish the the currnet iteration and exit gracefully.  See Also: Halt
  #
  # Example:
  #   fm = FileMonitor.new {|watched_item| puts 'do something when file is changed'}
  #   fm.spawn        # and now its doing its job...
  #   fm.stop
  def stop()
    # Send user defined signal USR1 to process.  This is trapped in spauned processes and tells the process to Ctrl+C
    # The user defined signial is sent as a safty percausion because the process id is not tracked through a pid file
    # nor compared with the running command.  The FileMonitor spaun will respond to the USR1 signal by exiting properly.*
    if Fixnum === @pid
      Process.kill('USR1', @pid)
      Process.wait @pid
    end
  end
  
  # Halts a spawned FileMonitor Instance.  The current iteration will be halted in its tracks.  See Also: stop
  #
  # Example:
  #   fm = FileMonitor.new {|watched_item| puts 'do something when file is changed'}
  #   fm.spawn        # and now its doing its job... 
  #   fm.stop
  def halt()
    if Fixnum === @pid
      Process.kill('USR2', @pid)
      Process.wait @pid
    end
  end
  
  def directories #:nodoc:
    @directories ||= []
  end
private
  # Returns true or false
  def process_running?
    pid ? !`ps -p #{pid}|grep ^[0-9]`.split().empty? : false
  end

  # Call callback and update digest with given key.
  def respond_to_change(item, key)
    if Proc === item.callback     # Use watched instance callback if possible.
      call item.callback, item, self
    elsif Proc === self.callback  # Use object level callback if possible.
      call self.callback, item, self
    end
    item.digest(key)
  end

  # Calls a proc with no more then the needed arguments.  This avoids an error when
  # calling a proc with two arguments when the proc only handels one argument.
  def call(proc, *args)
    if proc.arity > 0
      proc.call(*args[0..(proc.arity-1)])
    else
      proc.call
    end
  end

  # Returns new digest if changed or false if unchanged.
  def changed?(item)
    d = digest(item.path)         # get current digets
    d == item.digest ? false : d  # return new digest or false if unchanged
  end

  # Returns a string representation of the file state.
  def digest(file)
    begin
      ::File.mtime(file).to_f
    rescue Errno::ENOENT
      nil
    end
  end

  # Returns an array of all files in dirname recursively.  Accepts an optional file name regexp filter.
  # The following will find files ending in ".rb" recursively beginning in the working dir:
  #   files_recursive Dir.pwd, /\.rb$/
  def files_recursive(dirname, file_name_regexp=/.*/)
    paths = []
    
    Find.find(dirname) do |path|
      if FileTest.directory?(path)
        directories <<  MonitoredItems::Store.new({:path => ::File.expand_path(path), :file_name_regexp => file_name_regexp})
        ::Find.prune if ::File.basename(path)[0] == ?. # Don't look any further into directies beginning with a dot.
      else
        paths << path if file_name_regexp === path # Amend the return array if the file found matches the regexp
      end
    end
    
    return paths
  end
  
  # Attempts to add all files in all watched directories that match the watching filter, the add method is responcibale 
  # for managing duplicates.
  def scan_directories
    self.directories.each do |stored_directory|
      ::Dir.new(stored_directory.path).each do |file|
        unless file == '.' || file == '..'
          add(::File.join(stored_directory.path, file)) if stored_directory.file_name_regexp===file
        end
      end
    end
  end
end
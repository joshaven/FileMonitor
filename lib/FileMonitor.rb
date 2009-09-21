require File.dirname(__FILE__) + '/FileMonitor/store'

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
  attr_accessor :spawns
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
  
  # FileMonitor.when_modified(Dir.pwd, "/path/to/other/file.rb") do |watched_item| ... end
  def when_modified(*paths, &callback)
    puts "paths: #{paths.inspect}\ncallback.nil?: #{callback.nil?}"
    # paths.each do |path|
    #   
    # end
  end
  
  def add(path, &callback)
    if File.file? path
      i = MonitoredItems::Store.new
      i.file      File.expand_path(path)
      i.callback  callback
      @watched << i
      # @watched << MonitoredItems::Store.new({:file => File.expand_path(path), :callback => callback})
      return true
    elsif File.directory? path
      files_recursive(path).each {|f| add(f, &callback) }
      return true
    end
    false
  end

  def changes?
    return first_changed
  end

  def process
    # itterates watched files and runs callbacks when changes are detected.
    @watched.each do |i|
      key = digest(i.file)
      i.digest key if i.digest.nil?  # skip first change detection, its always unknown on first run
      update(i, key) unless i.digest == key
    end
  end

  def watching
    # Returns an Array of files being watched
    @watched
  end

  def monitor(interval = 1)
    trap("INT") do 
      STDERR.puts "  Interrupted by Control-C"
      exit 2
    end

    while true
      process
      sleep interval
    end
  end
  
  # Need to finish... needs to return true/false regarding the existance of the path being watched
  def watching?(path)
    
  end

  def spawn(interval = 1)
    if @spawns.nil? 
      @spawns = fork {monitor interval}
      Process.detach(@spawns)
      Kernel.at_exit do
        Process.kill('HUP', @spawns)
        @spawns = nil
      end
      true
    else
      @spawns
    end
  end
private
  def update(item, key)
    item.callback.call(item) unless item.callback.nil?
    item.digest key
  end
  # def update(item, key)
  #   item.callback.call( *(item.callback.arity==2 ? [item, self] : [item]) )
  #   item.digest key
  # end

  def first_changed
    # returns first changed item or false
    @watched.each {|i| return i if changed? i}
    false
  end

  def changed?(item)
    # returns md5 if changed, returns false when not changed
    md5 = digest(item.file) 
    md5 == item.digest ? false : md5
  end

  def digest(file)
    # returns the md5 of a file
    # Digest::MD5.hexdigest( File.read(file) )
    File.mtime(file)
  end

  def files_recursive(dirname)
    # return an array of files from this (dirname) point forth.
    Dir["#{dirname}/**/**"].collect {|f| f if File.file? f }.compact
  end
end
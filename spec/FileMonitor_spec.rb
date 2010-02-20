require File.dirname(__FILE__) + '/spec_helper.rb'

describe "FileMonitor" do
  before :all do
    @app_root = File.expand_path(File.dirname(__FILE__)+"/..")
  end
  
  it 'should be able to instantize' do
    fm = FileMonitor.new
    FileMonitor.should === fm
  end
  
  it 'should support adding files' do
    fm = FileMonitor.new
    fm.watched.size.should == 0
    (fm << @app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file using the '<<' method
    fm.watched.size.should == 1
    (fm.add @app_root + '/lib/FileMonitor/store.rb').should be_true  # Should add single file using the 'add' method
    fm.watched.size.should == 2
  end
  
  it 'should add files recursively when given a directory as a path' do
    fm = FileMonitor.new
    fm.watched.size.should == 0
    fm.add(@app_root + '/lib').should be_true  # Should add single file
    fm.watched.size.should > 1
  end
  
  it 'should respond to index_of' do
    fm = FileMonitor.new
    fm.add(@app_root + '/lib').should be_true  # Should add single file
    fm.watched.size.should > 1
    fm.index_of(@app_root + '/lib/FileMonitor.rb').should < fm.index_of(@app_root + '/lib/FileMonitor/store.rb')
    fm.index_of(@app_root + '/lib/not_here.txt').should be_false
  end
  
  it 'should support a FileMonitor object level callback' do
    fm = FileMonitor.new {true}
    fm.callback.arity.should == -1
    
    fm = FileMonitor.new {|watched_item| true}
    fm.callback.arity.should == 1
    
    fm = FileMonitor.new {|watched_item, file_monitor| true}
    fm.callback.arity.should == 2
  end
  
  it 'should support adding files with individual callbacks' do
    proc1 = Proc.new {return "hello from proc 1"}
    proc2 = Proc.new {return "hello from proc 2"}
    fm = FileMonitor.new &proc1
    (fm << @app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
    (fm.add @app_root + '/lib/FileMonitor/store.rb', &proc2).should be_true  # Should add single file
    fm.watched.first.callback.should be_nil
    fm.watched.last.callback.should == proc2
    fm.watched.last.callback.should_not == proc1
  end
  
  it 'should not duplicate files' do
    fm = FileMonitor.new
    filename = @app_root + '/lib/FileMonitor.rb'
  
    3.times do
      fm << filename
    end
    fm.watched.size.should == 1
  end  
  
  it 'should spawn processes' do
    fm = FileMonitor.new
    @app_root = "/Users/joshaven/projects/FileMonitor"

    fm << @app_root + '/lib'
    pid = fm.spawn
    pid.should_not == Process.pid
    `ps -p #{fm.spawn} -o 'pid ppid'`.split().should == ["PID", "PPID", pid.to_s, Process.pid.to_s]
    fm.stop
  end
  
  it 'should stop spawn' do
    fm = FileMonitor.new
    fm << @app_root + '/lib'
    pid = fm.spawn
    sleep 1
    # `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should == [pid.to_s, Process.pid.to_s]
    `ps -p #{fm.spawn} -o 'pid ppid'`.split().should == ["PID", "PPID", pid.to_s, Process.pid.to_s]
    t=Time.now
    fm.stop
    puts "Time to stop: #{Time.now-t}"
    `ps -p #{fm.spawn} -o 'pid ppid'`.split().should == ["PID", "PPID"]
  end
  
  it 'should halt spawn' do
    fm = FileMonitor.new
    fm << @app_root + '/lib'
    pid = fm.spawn
    sleep 1
    # `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should == [pid.to_s, Process.pid.to_s]
    `ps -p #{fm.spawn} -o 'pid ppid'`.split().should == ["PID", "PPID", pid.to_s, Process.pid.to_s]
    t=Time.now
    fm.halt
    puts "Time to halt: #{Time.now-t}"
    `ps -p #{fm.spawn} -o 'pid ppid'`.split().should == ["PID", "PPID"]
  end
  
  it 'should setup & spawn using the when_modified class method' do
    fm = FileMonitor.when_modified(Dir.pwd, "/path/to/other/file.rb") {|watched_item| true}
    fm.callback.arity.should == 1
    fm.pid.should > 1
    fm.pid.should == fm.spawn
    fm.stop
  end
  
  it 'should run callback on change' do
    changed_files = nil
    filename = @app_root + '/spec/temp.txt'
    File.open(filename, 'w') {|f| f.write('hello') }
    
    fm = FileMonitor.new() {|watched_item| changed_files = watched_item.path}
    fm << filename
    
    original = fm.watched.first.digest
    sleep 1
    File.open(filename, 'w') {|f| f.write('hello world') }
    fm.process
    fm.watched.first.digest.should_not == original
    File.delete filename
  end
  
  it 'should use item callback if possible, otherwise object callback' do
    @global_callback = []
    @files_callback = []
    file1 = @app_root + '/spec/temp1.txt'
    file2 = @app_root + '/spec/temp2.txt'
    file3 = @app_root + '/spec/temp3.txt'
    
    [file1,file2,file3].each {|file| File.open(file, 'w') {|f| f.write('hello') }}
    
    fm = FileMonitor.new() {|watched_item| @global_callback << watched_item.path }
    fm << file1
    fm.add(file2) {|watched_item| @files_callback << watched_item.path }
    fm << file3
    
    sleep 1
    [file1,file2,file3].each {|file| File.open(file, 'w') {|f| f.write('Hello World') }}
    fm.process
    
    @global_callback.should == [file1,file3]
    @files_callback.should == [file2]
    [file1,file2,file3].each {|file| File.delete(file)}
  end
  
  it 'should have access to local, FileMonitor & Store contexts' do
    filename = @app_root + '/spec/temp.txt'
    File.open(filename, 'w') {|f| f.write('hello') }
    
    fm = FileMonitor.new() do |watched_item, file_monitor| 
      MonitoredItems::Store.should === watched_item
      Spec::Example::ExampleGroup::Subclass_1.should === self
      FileMonitor.should === file_monitor
    end
    fm << filename
    sleep 1
    File.open(filename, 'w') {|f| f.write('hello world') }
    fm.process
    
    File.delete filename
  end
  
  it 'should not remove a file from the watch list if set to persistent when the file is deleted' do
    changed_files = []
    filename = @app_root + '/spec/temp.txt'
    File.open(filename, 'w') {|f| f.write('Hello World') }
  
    fm = FileMonitor.new({:persistent => true}) {|watched_item| changed_files << watched_item.path}
    fm << filename
  
    File.delete filename
    File.exists?(filename).should be_false
    fm.process.should be_true
    fm.watched.size.should == 1
    fm.watched.first.path.should == filename
  end
  
  it 'should remove a file from the watch list if not set to persistent when the file is deleted' do
    changed_files = []
    filename1 = @app_root + '/spec/temp1.txt'
    filename2 = @app_root + '/spec/temp2.txt'
    File.open(filename1, 'w') {|f| f.write('Hello World 1') }
    File.open(filename2, 'w') {|f| f.write('Hello World 2') }
  
    fm = FileMonitor.new() {|watched_item| changed_files << watched_item.path}
    fm << filename1
    fm << filename2
  
    fm.watched.size.should == 2
    File.delete filename2
    File.exists?(filename2).should be_false
    fm.process.should be_true
    fm.watched.size.should == 1
    fm.watched.first.path.should == filename1
    File.delete filename1
  end
  
  it 'should handel missing files without throwing errors' do
    filename = @app_root + '/spec/temp.txt'
    File.open(filename, 'w') {|f| f.write('hello') }
    fm = FileMonitor.new(:persistent => true) {true}
    fm << filename
    fm.process
    File.delete(filename)
    fm.process
    fm.watched.first.digest.should be_nil
  end
  
  it 'should be able to use a filter when specifying files' do
    fm = FileMonitor.new() {|watched_item| changed_files = watched_item.path}
    fm.add(@app_root, /\.rb$/) {|f| puts "Change found in: #{f.path}"}
    fm.watched.each do |i|
      File.split(i.path).last.should =~ /\.rb$/
    end
  end
  
  it 'should add new files when they are created if FileMonitor is watching a directory' do
    fm = FileMonitor.new
    # Create a test directory and watch it
    testing_dir = @app_root + '/spec/testing'
    filename = testing_dir + '/temp.txt'
    File.delete filename if File.exists?(filename)
  
    Dir.mkdir testing_dir unless File.directory? testing_dir
    fm << testing_dir
  
    fm.watched.should be_empty
  
    File.open(filename, 'w') {|f| f.write('hello') }
  
    # The new file should be watched after the fm.process has run
    fm.process
    fm.watched.should_not be_empty
  
    # Cleanup
    File.delete filename
    Dir.delete testing_dir
  end
end
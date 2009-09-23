require File.dirname(__FILE__) + '/spec_helper.rb'

# Time to add your specs!
# http://rspec.info/
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
    fm.watching.size.should == 0
    (fm << @app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file using the '<<' method
    fm.watching.size.should == 1
    (fm.add @app_root + '/lib/FileMonitor/store.rb').should be_true  # Should add single file using the 'add' method
    fm.watching.size.should == 2
  end
  
  it 'should add files recursively when given a directory as a path' do
    fm = FileMonitor.new
    fm.watching.size.should == 0
    fm.add(@app_root + '/lib').should be_true  # Should add single file
    fm.watching.size.should > 1
  end
  
  it 'should support a FileMonitor object level callback' do
    FileMonitor.new {|i| puts i}.should be_true
    FileMonitor.new {|i,j| puts i}.should be_true
    FileMonitor.new {|i,j,x| puts i}.should be_true
    # fm.add(@app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
  end
  
  it 'should support adding files with individual callbacks' do
    proc1 = Proc.new {return "hello from proc 1"}
    proc2 = Proc.new {return "hello from proc 2"}
    fm = FileMonitor.new &proc1
    (fm << @app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
    (fm.add @app_root + '/lib/FileMonitor/store.rb', &proc2).should be_true  # Should add single file
    fm.watching.first.callback.should be_nil
    fm.watching.last.callback.should == proc2
    fm.watching.last.callback.should_not == proc1
  end
  
  it 'should overwrite existing file watches with successive additions' do
    fm = FileMonitor.new
    fm.watching.size.should == 0
    (fm << @app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
    (fm << @app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
    fm.watching.size.should == 1
    
  end
  
  it 'should spawn processes' do
    fm = FileMonitor.new
    fm << @app_root + '/lib'
    pid = fm.spawn
    pid.should_not == Process.pid
    `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should == [pid.to_s, Process.pid.to_s]
  end

  it 'should stop spawn' do
    fm = FileMonitor.new
    fm << @app_root + '/lib'
    pid = fm.spawn
    `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should == [pid.to_s, Process.pid.to_s]
    t=Time.now
    fm.stop
    puts "Time to stop: #{Time.now-t}"
    `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should be_empty
  end
  
  it 'should halt spawn' do
    fm = FileMonitor.new
    fm << @app_root + '/lib'
    pid = fm.spawn
    `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should == [pid.to_s, Process.pid.to_s]
    t=Time.now
    fm.halt
    puts "Time to halt: #{Time.now-t}"
    `ps -p #{fm.spawn} -o 'pid ppid'|grep ^[0-9]`.split().should be_empty
  end
  
  
end
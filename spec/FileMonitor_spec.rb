require File.dirname(__FILE__) + '/spec_helper.rb'

# Time to add your specs!
# http://rspec.info/
describe "Place your specs here" do
  before :all do
    @app_root = File.expand_path(File.dirname(__FILE__)+"/..")
  end

  it 'should be able to instantize a FileMonitor' do
    fm = FileMonitor.new
    FileMonitor.should === fm
  end
  
  it "should support adding files" do
    fm = FileMonitor.new
    fm.watching.size.should == 0
    fm.add(@app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
    fm.watching.size.should == 1
  end
  
  it 'should support a FileMonitor object level callback' do
    fm = FileMonitor.new {|i| puts i}
    fm.add(@app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
  end
  
  it "should support adding files with individual callbacks" do
    fm = FileMonitor.new
    fm.watching.size.should == 0
    fm.add(@app_root + '/lib/FileMonitor.rb').should be_true  # Should add single file
    fm.watching.size.should == 1
  end
  
  
  
end

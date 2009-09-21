require File.dirname(__FILE__) + '/spec_helper.rb'

# Time to add your specs!
# http://rspec.info/
describe "FileMonitor::Store" do
  before :all do
    @item = MonitoredItems::Store.new
  end
  
  it "should store data and be accessable via mehtod() calls" do
    pth = Dir.pwd
    @item.file(pth).should == pth
    @item.file.should == pth
  end
  
  it "should store data and be accessable via mehtod()= calls" do
    pth = Dir.pwd
    (@item.file = pth).should == pth
    @item.file.should == pth
  end
  
  it 'should store keys as methods & values as data when initialized a hash' do
    i = MonitoredItems::Store.new({'string' => true, :symbol => true, :path => Dir.pwd})
    i.string.should be_true
    i.symbol.should be_true
    i.path.should == Dir.pwd
  end
  
  it 'should know how to to_h' do
    @item = MonitoredItems::Store.new
    @item.test true
    @item.hello = 'world'
    @item.to_h.should == {:test => true, :hello => 'world'}
  end
  
  it 'should know how to to_s' do
    @item = MonitoredItems::Store.new
    @item.test true
    @item.hello = 'world'
    @item.to_s.should == '{:test=>true, :hello=>"world"}'
  end
end

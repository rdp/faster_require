describe "faster requires" do
  
  $: << File.dirname(__FILE__)
  
  it "should require files still" do
    require 'file1'
  end
  
  it "should require .so files still" do
    # require ruby-prof gem
    require 'ruby_prof'
  end
  
  it "should use line number"
  
  it "should work with and without rubygems, esp. in 1.8"
  
  it "should have a faster require method"
  
  
end
require File.dirname(__FILE__) + '/../spec_helper.rb'

describe AppKernel::Validation do
  
  
  it "can do assertions which are associated with a field" do
    validate({:foo => 'bar'}) do
      @foo.check(!@foo.nil?, "'foo' cannot be nil")
    end.should be_empty
    
    validate({:foo => nil}) do
      @foo.check(!@foo.nil?, "cannot be nil.")
    end[:foo].should == "cannot be nil."
  end

  it "returns a positive result if there is no validation body passed" do
    validate().should be_empty
  end
  
  
  it "can validate fixnum fields fixnums" do
    validate({:num => 5}) do
      @num.check(@num < 5, "too big number!")
    end[:num].should == "too big number!"
  end
  
  def validate(vars = {}, &block)
    v = AppKernel::Validation::Validator.new(&block)
    v.validate vars
  end

end

require File.dirname(__FILE__) + '/../spec_helper'

describe "Type Conversion" do
  
  describe "Boolean" do
    
    it "should convert values the correct values into true, everything else should be false" do
      tb("true").should be(true)
      tb("True").should be(true)
      tb("t").should be(true)
      tb("y").should be(true)
      tb("yes").should be(true)
      tb("on").should be(true)

      tb('1').should be(false)
      tb('off').should be(false)
      tb('false').should be(false)
      tb('Phil Trotill').should be(false)
    end
    
    it "can call with a boolean function" do
      function = Class.new(AppKernel::Function).class_eval do
        self.tap do
          option :bool, :type => AppKernel::Boolean, :index => 1
          def execute
            @bool
          end
        end
      end
      
      function.call("true").should == true
    end

  end
  
  describe "Numeric" do
    it "converts integers" do
      t(Integer,"5").should == 5
    end
    
    it "converts floats" do
      t(Float, "3.14").should == 3.14
    end
  end
  
  def t(type, str)
    type.to_option(str)
  end
  
  def tb(str)
    t(AppKernel::Boolean, str)
  end
  
end
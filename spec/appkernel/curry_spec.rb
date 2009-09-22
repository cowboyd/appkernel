require File.dirname(__FILE__) + '/../spec_helper'

describe "Function Currying " do
  
  before(:each) do
    @mult = Class.new(AppKernel::Function).class_eval do
      self.tap do
        option :lhs, :index => 1, :type => Numeric, :required => true
        option :rhs, :index => 2, :type => Numeric, :required => true
                
        def execute
          @lhs * @rhs
        end
        
      end
    end        
    
  end
  
  it "new functions to be created by fixing values of specified options" do    
    @mult.curry(2).tap do |double|
      double.call(3).should == 6
      double.call(:rhs => 10).should == 20
    end
    
  end
  
  it "is an error to curry options that do not exists" do
    lambda {
      @mult.curry(:hello => "world")
    }.should raise_error(AppKernel::OptionsError)
  end
  
  it "the curried options will not be overriden and in fact will raise an error if an attempt is made to do so" do
    lambda {
      @mult.curry(:lhs => 2).call(:lhs => 4, :rhs => 5)
    }.should raise_error(AppKernel::OptionsError)
  end
  
  it "requires all curried options to go through resolution and type matching" do
    Class.new(AppKernel::Function).class_eval do
      option :int, :type => Integer
      option :float, :type => Float
      
      def execute
        @float + @int
      end
      
      self.curry(:float => "3.14").call(:int => 5).should == 8.14
    end
  end
  
  it "is an error to have a nil value for a curried option if that option is required" do
    lambda {
      @mult.curry(:lhs => nil)
    }.should raise_error(AppKernel::OptionsError)
  end
  
  it "automatically nils out an option if it is curried with nil" do
    Class.new(AppKernel::Function).class_eval do
      option :one
      option :two
      
      def execute
        [@one, @two]
      end
      
      curry(:one => nil).call(:two => 2).should == [nil,2]
    end
  end
  
  it "allows functions to be curried multiple times" do
    @mult.curry(:lhs => 2).curry(:rhs => 3).call.should == 6
  end
end
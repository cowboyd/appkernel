require File.dirname(__FILE__) + '/../spec_helper'

describe AppKernel::Function do

  before(:each) do
    @function = Class.new(AppKernel::Function)
  end

  def class_eval(&block)
    @function.class_eval(&block)
  end


  describe "Calling Conventions" do
    it "allows modules to define an function functions that takes options" do
      class_eval do
        option :word

        def execute
          @word
        end
      end

      @function.call(:word => "hello").should == "hello"
    end

    it "allows certain options to be the default option" do

      class_eval do
        option :greeting, :index => 0
        option :to, :index => 1
        option :extra

        def execute
          "#{@greeting} #{@to}#{(', ' + @extra) if @extra}"
        end
      end
      @function.call("Hello", "Charles", :extra => "How are you?").should == "Hello Charles, How are you?"
      @function.call("Hello", "Charles").should == "Hello Charles"
      @function.call(:greeting => "Hello", :to => "Charles").should == "Hello Charles"
    end


    it "can be called by using the apply method instead of invoking it directly" do
      class_eval do
        option :desc, :index => 1

        def execute
          "FiveAlive is a #{@desc}"
        end
      end
      result = @function.apply("candy bar")
      result.return_value.should == "FiveAlive is a candy bar"
      result.successful?.should be(true)
    end

    it "can have required options, but they are never required by default" do
      class_eval do
        option :greeting, :index => 1, :required => true
        option :to, :index => 2, :required => true
        option :extra, :index => 3
      end

      @function.apply("Hello", "World", "I'm doing fine.").tap do |result|
        result.successful?.should be(true)
      end

      @function.apply.tap do |result|
        result.return_value.should be(nil)
        result.should_not be_successful
        result.errors[:greeting].should_not be_empty
        result.errors[:to].should_not be_empty
        result.errors[:extra].should be_empty

        result.errors.length.should be(2)
      end
    end
  end

  describe "Error Handling" do
      
    it "raises an error immediately if you try to call a function that has invalid arguments" do
      class_eval do
        option :mandatory, :required => true
      end

      lambda {
        @function.call()
      }.should raise_error(AppKernel::OptionsError)
    end

    it "allows validation of its arguments" do
      class_eval do
        option :arg, :index => 1

        def validate(this)
          this.check(@arg == 5 && @arg != 6, "'arg' must be 5 and not be 6")
        end

      end

      @function.apply(5).should be_successful
      @function.apply(6).tap do |result|
        result.should_not be_successful
        result.errors.to_a.should == ["'arg' must be 5 and not be 6"]
      end

    end
    
    it "allows associating arbitrary tags with errors" do
      class_eval do
        def validate(this)
          this.check(false, "Not!", :tag)
        end
      end
      
      @function.apply.errors[:tag].should_not be_nil
    end
    
    it "supports hash syntax for specifying error tags"
    
    it "throws a tag instead of OptionsError validation error if tag is an instance of Error"
  end

  describe "Option Resolution" do
    it "can take a lookup parameter in the function definition which tells it how to lookup arguments" do
      class_eval do
        option :num, :index => 1, :lookup => proc {|s| s.to_i}

        def execute
          @num
        end
      end

      @function.call("5").should == 5
    end
    
    it "has a :parse options which are aliases for :lookup" do
      class_eval do
        option :num1, :index => 1, :lookup => proc {|s| s.to_i}
        option :num2, :index => 2, :parse => proc {|s| s.to_i}
        
        def execute
          [@num1,@num2]
        end
      end
      
      @function.call("1", "2").should == [1,2]
    end
    
    it "has default parsers/lookups if the type is specified" do
      class_eval do
        option :num, :type => Integer
        option :float, :type => Float
        
        def execute
          OpenStruct.new({
            :num => @num,
            :float => @float
          })
        end
      end
      
      @function.call(:num => "5", :float => "3.14").tap do |result|
        result.num.should == 5
        result.float.should == 3.14
      end
    end
    
    it "doesn't do an argument conversion if the argument is already of the correct type" do
      class_eval do
        option :num, :index => 1, :type => Integer, :lookup => proc {|s| raise StandardError, "Hey, don't call me!"}
        
        def execute
          @num
        end
      end
      lambda {
        @function.call(5)
      }.should_not raise_error        
    end
    
    it "accepts nil as a valid instance of all types" do
      class_eval do
        option :num, :index => 1, :type => Numeric
      end
      
      @function.call.should be_nil
      @function.call(:num => nil).should be_nil
    end
    
    it "triggers an error if an option is required and after trying to find it, it is still nil." do
     objects = {:foo => 'bar', :baz => "bang" }
    
      class_eval do
        option :obj, :index => 1, :required => true, :lookup => proc {|key| objects[key]}
        def execute
          @obj
        end
      end
      
      @function.call(:foo).should == 'bar'
      @function.call(:baz).should == 'bang'
      lambda {
        @function.call(:bif)
      }.should raise_error    
    end
    
    it "triggers an error if an option is unknown" do
     lambda {
       @function.call(:foo => 'bar')
     }.should raise_error(AppKernel::OptionsError)
    end
    
    it "is an error if the resolved option is not of the specified type"
  
    describe "Default Values" do
      it "allows for any option to have a default value" do
        class_eval do
          option :value, :default => 5

          def execute
            @value
          end
        end

        @function.call.should == 5
      end

      it "requires that the default value be the same as the option type if that is specified" do
        lambda {
          class_eval do
            option :value, :type => Integer, :default => "NOT_INT"
          end
        }.should raise_error(AppKernel::IllegalOptionError)
      end
      
      it "sets a default option even if that option is explicitly passed in as nil" do
       class_eval do
        option :value, :default => 'fun'
  
        def execute
          @value
        end
       end
       @function.call(:value => nil).should == 'fun'
      end
            
      it "allows false as a default value" do
        class_eval do
          option :bool, :index => 1, :default => false
          def execute
            @bool
          end
        end
        @function.call().should be(false)
      end        
    end

    describe "Complex Types" do
      it "takes options that have multiple valid types" do
        class_eval do
          option :bool, :index => 1, :type => [TrueClass, FalseClass], :parse => proc {|s| s == "true"}          
          def execute
            @bool
          end
        end
      
       @function.call("true").should be(true)
       @function.call("false").should be(false)
       @function.call(true).should be(true)
       @function.call(false).should be(false)
      end
      
      it "raises an exception if it can't tell how to find a complex type" do
       weird = Class.new
       class_eval do
        option :weird, :type => weird
        def execute
          @weird
        end
       end     
       lambda {
         @function.call(:weird => "weird")
       }.should raise_error
      
       weird.new.tap do |w|
         @function.call(:weird => w).should == w
       end
      end
    end

  end

end
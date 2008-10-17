require 'spec'
require 'appkernel'

describe AppKernel do
	before(:each) do
		@kernel = AppKernel.new
		@bar = @kernel[:bar] = Object.new
		@service = Class.new(AppKernel::Service)
		@service.class_eval do
			attr_reader :bar
			uses :bar
		end
	end

	it "adds a option-based constructor into service classes" do
		instance = @service.new(:bar => :baz)
		instance.bar.should == :baz
	end
	
	it "can store and retrieve instances by key" do
		o = Object.new
		@kernel[:foo] = o
		@kernel[:foo].should == o
	end
	
	it "records dependencies of service classes and uses them to instaniate it" do		
		@kernel[:bar] = Object.new
		@kernel.register(@service)
		@kernel[@service].bar.should == @kernel[:bar]
		
		@kernel[@service].should == @kernel[@service]
	end
	
	it "handles multiple and transitive dependencies" do
		@s2 = Class.new(AppKernel::Service)
		@s2.class_eval do
			attr_reader :service, :bar
			uses :service
			uses :bar
		end
		@kernel[:service] = @service
		@kernel.register(@s2)
		s2 = @kernel[@s2]
		s2.service.class.should be(@service)
		s2.bar.should be(@bar)
	end
		
	it "chooses the closest possible match when resolving class-keyed dependencies that are not explicity specified" do
		@subservice = Class.new(@service)
		@kernel.register(@subservice)
		@s2 = Class.new(AppKernel::Service)
		dependency = @service
		@s2.class_eval do
			attr_reader :service
			uses dependency, :field => :service
		end
		@kernel.register(@s2)
		s2 = @kernel[@s2]
		s2.service.class.should be(@subservice)
	end
	
	
	it "for class-keyed dependencies, it chooses a reasonable field name if one is not set explicitly" do
		class FooBarBaz < AppKernel::Service
			
    end
		
		class Banger < AppKernel::Service
			attr_reader :foo_bar_baz
			uses FooBarBaz
    end
		
		@kernel.register(FooBarBaz)
		@kernel.register(Banger)
		
		b = @kernel[Banger]
		b.foo_bar_baz.class.should be(FooBarBaz)
  end
	
	it "removes old instances when an implementation of the classes changes" do
		@kernel.register(@service)
		impl = @kernel[@service]
	
		@subservice = Class.new(@service)
		@kernel.register(@service, @subservice)
		
		@kernel[@service].should_not be(impl)
		@kernel[@service].class.should be(@subservice)
  end
	
	it "is always available as the default kernel implementation" do
		@kernel[AppKernel].should be(@kernel)
  end
	
	it "handles service class hierarchies correctly in that it passes all dependencies needed to the superclass"
	
	
	it "can define and call executeable commands" do
		bangval = nil
		@cmd = Class.new(AppKernel::Command)
		@cmd.class_eval do
			option :bang, :type => String #, :required => true, :metavar => 'STR', :alias => 'v', :desc => "", :multivalued => false
			
    	whenexecuted do
				bangval = @bang
      end
			
    end
		
		@kernel.exec(@cmd, :bang => 'san')
		bangval.should == 'san'
  end
	
	it "passes services to commands to resolve dependencies just like other services" do
		barval = nil
		@cmd = Class.new(AppKernel::Command)
		@cmd.class_eval do
			uses :bar
			
    	whenexecuted do
				barval = @bar
      end
    end
		@kernel.exec(@cmd)
		barval.should == @bar
  end
	
	it "converts string arguments into floats if possible" do
		ival = nil
		fval = nil
		@cmd = Class.new(AppKernel::Command)
		@cmd.class_eval do
			option :i, :type => Integer
			option :f, :type => Float
			
			
    	whenexecuted do
			 ival = @i;fval = @f	
      end
    end
		@kernel.exec(@cmd, :i => "7", :f => "3.14")
		ival.should == 7
		fval.should == 3.14
  end
	
	it "can accept new ways to resolve strings into objects, and to aid in doing so, it passes in a copy of the kernel itself" do
		k = nil
		@kernel.resolves(Integer) {|kernel, spec| k = kernel; spec == 'five' ? 5 : 7}
		@cmd = Class.new(AppKernel::Command)
		ival = nil
		@cmd.class_eval do
			option :i, :type => Integer
    	whenexecuted do
				ival = @i
      end
    end
		@kernel.exec(@cmd, :i => "five")
		ival.should == 5
		@kernel.exec(@cmd, :i => "seven")
		ival.should == 7
		k.should be(@kernel)
  end
	
	it "validates the input to a command with the, and does not execute the command itself if it is not valid" do
		executed = false
		@cmd = Class.new(AppKernel::Command)
		@cmd.class_eval do
			option :wives, :type => Integer
			
			validate {
				#ruby gives us the option of some pretty cool shit. alternative options
        #@wives.must_be either(1).or(0)
#				@wives.must eql(0).or(1)
#				@wives.must not.equal(0) 
				@wives.must_be lessthan(5).and.greaterthan(6)
#				@wives.check @wives == 0 || @wives == 1,  "polygamist!"
				check :wives, @wives == 0 || @wives == 1, "polygamist!"
      }
    	whenexecuted {
				executed = true
      }
    end
		
		cmd = @kernel.exec(@cmd, :wives => 5)
		executed.should be(false)
		cmd.success?.should be(false)
		cmd.errors[:wives].should == "wives must be less than 5 but greater than 6"
  end
	
	it "can evaluate commands from a command like utility"
end
require File.dirname(__FILE__) + '/../spec_helper'
  
describe AppKernel::Function do
  
  before(:each) do
    @mod = Module.new do |mod|
      mod.module_eval do
        include AppKernel::Function
      end
    end
    extend @mod
    @klass = Class.new.class_eval do
      include AppKernel::Function; self
    end
  end
  
  it "allows modules to define an function functions" do
    @mod.module_eval do
      function :Say do        
        option :word
        
        execute do
          @word
        end
      end
      Say(:word => "hello").should == "hello"
    end
  end
  
  it "allows certain options to be the default option" do
    @mod.module_eval do
      function :Say do
        option :greeting, :index => 0
        option :to, :index => 1
        option :extra
        
        execute do
          "#{@greeting} #{@to}#{(', ' + @extra) if @extra}" 
        end
      end
      
      
      Say("Hello", "Charles", :extra => "How are you?").should == "Hello Charles, How are you?"
      Say("Hello", "Charles").should == "Hello Charles"
      Say(:greeting => "Hello", :to => "Charles").should == "Hello Charles"
    end
  end
  
  it "allows classes that include the module to also use the commands from that module" do
    @mod.module_eval do
      function :Included do
        execute do
          "It worked!"
        end
      end
    end
    mod = @mod
    Class.new(Object).class_eval do
      include mod
      self
    end.new.instance_eval do
      Included().should == "It worked!"
    end
  end
  
  it "allows classes to define functions as well as modules" do
    @klass.class_eval do
      function :Say do
        option :word, :index => 1
        execute do
          @word
        end
      end      
    end
  end
  
  it "can be called by using the apply method instead of invoking it directly" do
    @mod.module_eval do
      function :FiveAlive do
        option :desc, :index => 1
        execute do
          "FiveAlive is a #{@desc}"
        end
      end  
    end
    result = apply(@mod::FiveAlive, "candy bar")
    result.return_value.should == "FiveAlive is a candy bar"
    result.successful?.should be(true)
  end
  
  it "can have required options, but they are never required by default" do
    @mod.module_eval do
      function :Say do
        option :greeting, :index => 1, :required => true
        option :to, :index => 2, :required => true
        option :extra, :index => 3
      end      
    end
    result = apply(@mod::Say, "Hello", "World", "I'm doing fine.")
    result.successful?.should be(true)
    result = apply(@mod::Say)
    result.return_value.should be(nil)
    result.successful?.should be(false)
    result.errors[:greeting].should_not be(nil)
    result.errors[:to].should_not be(nil)
    result.errors[:extra].should be(nil)
  end
  
  it "raises an error immediately if you try to call a function that has invalid arguments" do
    @mod.module_eval do
      function :Harpo do
        option :mandatory, :required => true
      end
    end

    lambda {
      Harpo()
    }.should raise_error(AppKernel::ValidationError)
  end
  
  it "allows validation of its arguments" do
    @mod.module_eval do
      function :Picky do
        option :arg, :index => 1                
        validate do
          @arg.check @arg == 5 && @arg != 6, "must be 5 and not be 6"
        end      
      end  
    end

    apply(@mod::Picky, 5).successful?.should be(true)
    result = apply(@mod::Picky, 6)
    result.successful?.should be(false)
    result.errors[:arg].should == "must be 5 and not be 6"
    
    result = apply(@mod::Picky, 7)
    result.successful?.should be(false)
    result.errors[:arg].should == "must be 5 and not be 6"
  end
end


# module Awacs::Ssid
#   include AppKernel::Function
#   
#   function :GetErrorCountBySource do
#     option :solr, :nil => false
#     option :source, :nil => false, :empty => false
#         
#     item = Struct.new(:source, :error_count)          
#     execute do
#       @solr.query("sys_error_marker:(\"SSID-AUGMENTATION-ERROR\")", 
#         :filter_queries => ["PublicationTitle_t:[* TO *]"],
#         :rows => 0,
#         :facets => {:fields => "sys_source_id", :mincount => 1, :limit => 1000, :sort => "count"}
#       ).data['facet_counts']['facet_fields']['sys_source_id'].enum_for(:each_slice, 2).map do |slice|
#         item.new(*slice)
#       end          
#     end                
#   end
#   
#   function :GetErrorCountByPublicationTitle do
#     option :solr, :nil => false
#     option :source, :nil => false, :empty => false
#     option :title, :nil => false, :empty => false
#     
#     item = Struct.new(:title, :error_count)
#     
#     execute do
#       @solr.query(%Q{sys_error_marker:("SSID-AUGMENT-FAILED")}, 
#       :filter_queries => %Q{sys_source_id:("#{@source}")}, 
#       :facets => {:fields => ['PublicationTitle_sfacet'], :mincount => 1, :limit => 1000, :sort => :count}
#       ).data['facet_counts']['facet_fields']['PublicationTitle_sfacet'].enum_for(:each_slice, 2).map do |slice|
#         item.new(*slice)
#       end
#     end
#   end
#   
#   
    # executeable :AddMapping do
    #   option :type, :nil => false, :type => SsidMatchType, :lookup => proc {|s| SsidMatchType.find_by_name s}
    #   option :value, :nil => false
    #   option :ssid, :nil => false
    #   
    #   execute do
    #     SsidMapping.create :match_rule => FindOrCreateRule(:type => @type, :value => @value), :ssid => @ssid
    #   end
    # end
    # 
    # function :DeleteMapping do
    #   option :mapping, :index => 1, :type => SsidMapping, :lookup => proc {|s| SsidMapping.find(s)}
    #   
    #   execute do
    #     @mapping.delete!
    #   end
    # end

#   function :SaveMappings do
#     option :adds, :default => [], :massage => proc {|o| [o].flatten}
#     option :deletes, :default => [], :massage => proc {|o| [o].flatten}
#   end
#   
# end
# 
# #later on....
# include Awacs::Ssid
# GetErrorCountBySource :source => "proquest"
# GetErrorCountByPublicationTitle, :source => "proquest", :title => "Journal of Water Law"
# AddMapping :rule => {:match_type => 'ISSN', :match_value => '001287'}, :ssid => '123459'
# AddMapping :rule => 89, :ssid => 1234569
# 

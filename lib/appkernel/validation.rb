require 'delegate'
module AppKernel::Validation
  class Validator
    
    attr_reader :errors
    
    def initialize(&block)
      @body = block
    end
    
    def validate(vars = {})
      errors = {}
      scope = Object.new
      for k,v in vars do
        val = case v
        when nil
          NilValue.new
        when Fixnum
          FixnumValue.new(v)
        else
          v.dup
        end
        val.extend Check
        val.instance_eval do
          @_add_validation_error = lambda {|message|
            errors[k] = message
          }
        end
        scope.instance_variable_set("@#{k}", val)
      end      
      scope.instance_eval &@body if @body
      errors
    end
    
  end
  
  module Check
    def check(condition, message)
      unless condition
        @_add_validation_error.call(message)
      end
    end
  end
  
  class NilValue < DelegateClass(NilClass)
    def initialize
      super(nil)
    end
    
    def nil?
      true
    end
  end
  
  class FixnumValue < DelegateClass(Fixnum)
    def initialize(val)
      super(val)      
    end
  end
end

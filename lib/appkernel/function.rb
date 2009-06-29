require 'set'

class AppKernel    
  module Function
    
    def apply(fun, *args)
      FunctionApplication.new(fun, *args)
    end
    
    def self.included(mod)
      class << mod
        def function(symbol, &definition)
          fun = ::AppKernel::FunctionDefinition.new(definition)
          self.const_set(symbol, fun)
          self.send(:define_method, symbol) do |*args|
            FunctionApplication.apply_or_die(fun, *args)
          end
          if self.class == Module      
            self.send(:module_function, symbol) 
          else
            class << self;self;end.send(:define_method, symbol) do |*args|
              FunctionApplication.apply_or_die(fun, *args)
            end
          end
        end
        
        def apply(fun, *args)
          FunctionApplication.new(fun, *args)
        end
      end
    end
  end
  
  class FunctionApplication
    
    attr_reader :return_value, :errors, :function, :options
    
    def initialize(fun, *args)
      @function = fun
      @args = args
      @options = {}
      @errors = {}
      @return_value = self.class.do_apply(self, *args)
    end
    
    def successful?
      @errors.empty?
    end
    
    class << self
      
      def apply_or_die(fun, *args)
        app = new(fun, *args)
        if app.successful?
          app.return_value
        else
          raise ValidationError, app
        end
      end
      
      def do_apply(app, *args)
        fun = app.function
        instance = Object.new
        indexed_options = fun.indexed_options
        required_options = Set.new(fun.options.values.select {|o| o.required?})
        for arg in args do
          if arg.kind_of?(Hash)
            arg.each do |k,v| 
              if opt = fun.options[k.to_sym]
                opt.set instance, v
                required_options.delete opt
                app.options[opt.name] = v
              end
            end
          elsif opt = indexed_options.shift
            opt.set instance, arg
            required_options.delete opt
            app.options[opt.name] = arg
          end
        end
        for opt in required_options do
          app.errors[opt.name] = "Missing required option '#{opt.name}'"
        end
        app.errors.merge! fun.validation.validate(app.options)
        instance.instance_eval &fun.impl if app.successful?
      end
    end    
  end
  
  class FunctionDefinition
    
    attr_reader :impl, :options, :validation
    
    def initialize(definition)
      @options = {}
      @impl = lambda {}
      @validation = ::AppKernel::Validation::Validator.new 
      self.instance_eval &definition
    end
    
    def option(name, params = {})
      name = name.to_sym
      @options[name] = Option.new(name, params)
    end
    
    def indexed_options
      @options.values.select {|o| o.index}.sort_by {|a| a.index}
    end
    
    def execute(&impl)
      @impl = impl
    end
    
    def validate(&checks)
      @validation = AppKernel::Validation::Validator.new(&checks)
    end
            
    class Option
      attr_reader :name, :index
      def initialize(name, params)
        @name = name
        @index = params[:index]
        @required = params[:required] == true
      end
            
      def set(o, value)
        o.instance_variable_set("@#{@name}", value)
      end
      
      def required?
        @required
      end
      
      def optional?
        !@required
      end
    end
    
    class Validator
    end
  end
  
  class ValidationError < StandardError
    def initialize(application)
      @app = application
    end
    
    def message
      @app.errors.values.first
    end
  end
    
end
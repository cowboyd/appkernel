require 'set'

class AppKernel    
  module Function
    
    def apply(fun, *args)
      FunctionApplication.new(fun, *args)
    end
    
    def self.included(mod)
      class << mod
        def function(symbol, &definition)
          fun = ::AppKernel::FunctionDefinition.new(symbol, self, definition)
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
    
    attr_reader :return_value, :errors, :function, :args
    
    def initialize(fun, *args)
      @function = fun
      @errors = {}
      @args = Arguments.new(self, *args)
      @return_value = self.class.do_apply(self)
    end
    
    def successful?
      @errors.empty?
    end
    
    def options
      @args.canonical
    end
    
    class Arguments   
      
      attr_reader :canonical
               
      def initialize(app, *args)
        fun = app.function
        @app = app
        @canonical = {}
        @required = Set.new(fun.options.values.select {|o| o.required?})      
        @optorder = fun.indexed_options  

        for arg in args
          if (arg.is_a?(Hash))
            arg.each do |k,v|
              if opt = fun.options[k.to_sym]
                set opt, v
              else
                raise FunctionCallError, "#{fun.name}: unknown option :#{k}"
              end 
            end
          elsif opt = @optorder.shift
            set opt, arg
          end
        end
        for opt in fun.options.values
          if @canonical[opt.name].nil? && !opt.default.nil?
            @canonical[opt.name] = opt.default
            @required.delete opt
          end
        end
        for opt in @required
          app.errors[opt.name] = "missing required option '#{opt.name}'"
        end
        for name in fun.options.keys
          @canonical[name] = nil if @canonical[name].nil?
        end        
      end
      
      def set(opt, value)
        resolved = opt.resolve(@app, value)      
        if !resolved.nil?
          @canonical[opt.name] = resolved
          @required.delete opt
        elsif !value.nil? && opt.required? 
          @required.delete opt
          @required.delete opt
          @app.errors[opt.name] = "no such value '#{value}' for required option '#{opt.name}'"          
        end
      end
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
      
      def do_apply(app)
        fun = app.function      
        app.errors.merge! fun.validation.validate(app.options) if app.successful?
        if app.successful?
          scope = Object.new
          scope.extend fun.mod
          for k,v in app.options do
            scope.instance_variable_set("@#{k}", v)
          end
          scope.instance_eval &fun.impl
        end
      end
    end    
  end
  
  class FunctionDefinition
    
    attr_reader :name, :mod, :impl, :options, :validation
    
    def initialize(name, mod, definition)
      @name = name
      @mod = mod
      @options = {}
      @impl = lambda {}
      @validation = ::AppKernel::Validation::Validator.new(self)
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
      @validation = AppKernel::Validation::Validator.new(self, &checks)
    end

    def to_s
      "#{@name}()"
    end
            
    class Option
      ID = lambda {|o| o}
      attr_reader :name, :index, :default
      def initialize(name, params)
        @name = name.to_sym
        @index = params[:index]
        @required = params[:required] == true
        @finder = params[:find]
        @types = params[:type] ? [params[:type]].flatten : nil
        @default = params[:default]
        validate!
      end
      
      def validate!
        if @default
          if @types
            raise OptionError, "#{@default} is not a kind of #{@types.join('|')}" unless @types.detect {|t| @default.kind_of?(t)}
          elsif @required
            Kernel.warn "option '#{@name}' unecessarily marked as required. It has a default value"
          end
        end
      end
                  
      def required?
        @required
      end
      
      def optional?
        !@required
      end
      
      def resolve(app, value)
        if value.nil?
          nil
        elsif @types 
          if @types.detect {|t| value.is_a?(t)}
            value
          elsif @finder
            lookup(app, value)
          else
            raise OptionError, "Don't know how to convert #{value.class}:#{value} -> #{@type}"
          end
        elsif @finder
          lookup(app, value)
        else
          value
        end
      end
      
      def lookup(app, value)
        result = @finder.call(value)
        app.errors[@name] = "couldn't find '#{@name}': #{value}" if result.nil? 
        result
      end                 
    end
    
    class Validator
    end
  end
  
  class FunctionCallError < StandardError; end
  class OptionError < StandardError; end
  
  class ValidationError < StandardError
    def initialize(application)
      @app = application
    end
    
    def message
      "#{@app.function.name}: #{@app.errors.values.first}"
    end
  end
    
end
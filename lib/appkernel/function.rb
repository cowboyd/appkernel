class AppKernel
  
  class IllegalOptionError < StandardError; end

  class Function
    class << self
      def inherited(subclass)
        super(subclass)
        subclass.send(:include, InstanceMethods)
        subclass.extend(ClassMethods)
        subclass.prepare!
      end
    end

    class Result
      attr_reader :errors
      attr_accessor :return_value

      def initialize
        @errors = Errors.new
      end

      def successful?
        @errors.empty?
      end

      def verify!
        raise ArgumentError, @errors[0] unless successful?
      end
    end

    class Errors
      include Enumerable

      def initialize
        @errors = Hash.new {|h, k| h[k] = []}
        @all = []
      end

      def add(tag, message)
        @errors[tag] << message if tag
        @all << message
      end

      def each(&block)
        @all.each(&block)
      end

      def [](tag)
        @errors[tag]
      end

      def length
        @all.length
      end

      def empty?
        @all.empty?
      end
    end

    module ClassMethods
      
      def options
        @options
      end

      def option(name, modifiers = {})
        @options.add(name, modifiers)
      end

      def prepare!
        @options = Options.new
        call = Module.new.tap do |mod|
          unless self.name.empty?
            fun = self
            path = self.name.split(/::/)
            simple_name = path[path.length - 1]
            fun_name = simple_name.gsub(/(\w)([A-Z])([a-z])/) {"#{$1}_#{$2.downcase}#{$3}"}.downcase
            mod.send(:define_method, fun_name) do |*args|
              fun.call(*args)
            end
          end
        end
        self.const_set(:Call, call)
      end

      def call(*args)
        apply(*args).tap {|result|
          result.verify!
        }.return_value
      end

      def apply(*args)
        Result.new.tap do |result|
          @options.canonicalize(args, result.errors).tap do |params|
            if result.successful?
              new(params).tap do |function|
                function.validate(Validator.new(result.errors))
                if result.successful?
                  result.return_value = function.execute
                end
              end
            end
          end
        end
      end
    end

    class Validator
      def initialize(errors)
        @errors = errors
      end

      def check(condition, message = "valditation failed", tag=nil)
        @errors.add(tag, message) unless condition
      end
    end

    module InstanceMethods
      def initialize(params)
        for k, v in params
          self.instance_variable_set("@#{k}", v)
        end
      end

      def execute
        #do something
      end

      def validate(this)
        
        #do something
      end
    end

    class Options
      
      attr_reader :options
      
      def initialize
        @options = {}
        @indexed = []
        @required = []
        @defaults = []
        @presets = {}
      end

      def add(name, modifiers)
        ingest Option.new(name, modifiers)
      end
      
      def ingest(o)        
        @options[o.name] = o
        if o.index
          @indexed[o.index] = o
          @indexed.compact!
        end
        @required << o.name if o.required?
        @defaults << o.name if o.default?
        if o.default? && o.type
          raise IllegalOptionError, "option '#{o.name}' is not a #{o.type}" unless o.default.kind_of?(o.type)
        end                
      end

      def canonicalize(args, errors, augment = true)
        args = args.dup
        @presets.dup.tap do |canonical|
          indexed = @indexed.dup
          while !(arg = args.shift).nil?
          # for arg in args
            case arg
              when Hash
                resolved = {}
                for k,v in arg
                  if opt = @options[k]
                    resolved[k] = opt.resolve(v)
                  else
                    raise ArgumentError, "unknown option '#{k}'"
                  end
                end
                canonical.merge! resolved
              else
                if opt = indexed.shift                  
                  canonical[opt.name] = opt.resolve(arg)
                  if opt.greedy?
                    while !args.first.nil? && !(args.first.kind_of?(Hash) || args.first.kind_of?(Array))
                      canonical[opt.name] += opt.resolve(args.shift)
                    end
                  end
                else
                  raise ArgumentError, "too many arguments"
                end
            end
          end
          if augment
            for k in @defaults
              canonical[k] = @options[k].default unless canonical[k]
            end
            canonical.reject! {|k,v| v.nil? || (@options[k] && @options[k].list? && v.empty?)}
            for k in @required - canonical.keys
              errors.add(k, "missing required option '#{k}'")
            end
          end
        end
      end
      
      class Option
        
        class ::Symbol
          def [](*dontcare)
            Option.new(self, :list => true)
          end

          def *(*dontcare)
            Option.new(self, :list => true, :greedy => true)
          end
        end
        
        attr_reader :name, :index, :type, :default, :modifiers

        def initialize(name, modifiers = {})
          if name.kind_of?(Option)
            modifiers = modifiers.merge(name.modifiers)
          end
          @name = name.to_sym
          @modifiers = modifiers
          @index = modifiers[:index]
          @required = modifiers[:required] == true
          @lookup = modifiers[:lookup] || modifiers[:parse]
          @type = modifiers[:type]
          @default = modifiers[:default]
          @list = modifiers[:list]
          @greedy = modifiers[:greedy]
        end

        def required?
          @required
        end
        
        def default?
          !@default.nil?
        end
        
        def list?
          @list
        end
        
        def greedy?
          @greedy
        end
                
        def to_sym
          @name
        end

        def resolve(o, single = false)
          if o.nil? then nil
          elsif @list && !single
            o.kind_of?(Array) ? o.map {|v| resolve(v,true)} : [resolve(o, true)]  
          elsif @type
            if @type.kind_of?(Class) && o.kind_of?(@type) then o
            elsif @type.kind_of?(Enumerable) && @type.detect {|t| o.kind_of?(t)} then o
            elsif @lookup
              @lookup.call(o)
            elsif @type.respond_to?(:to_option)
              @type.to_option(o)
            else
              raise ArgumentError, "don't know how to convert #{o} into #{@type}"
            end
          else
            @lookup ? @lookup.call(o) : o
          end                    
        end
      end
    end
  end
end
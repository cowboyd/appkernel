require 'appkernel/deps'
require 'appkernel/polymorphic_hash'

class AppKernel
	@dependencies = Hash.new {|h,k| h[k] = []}
	@options = Hash.new {|h,k| h[k] = []}
	@validators = Hash.new {|h,k| h[k] = []}
	@listeners = {}
	@commands = {}
	
  
	def initialize()
		@classes = PolymorphicHash.new
		@instances = PolymorphicHash.new
		@resolvers = PolymorphicHash.new
		resolves(Integer) {|spec| spec.to_i}
		resolves(Float) {|spec| spec.to_f}
		register(self)
	end
	
	def register(key, impl = nil)
		if !impl
			impl = key
			key = impl.is_a?(Class) ? impl : impl.class
		end
		@instances.delete(key)
		if impl.is_a?(Class)
			@classes[key] = impl
		else
			@instances[key] = impl
		end
	end
	
	def []=(key, impl)
		register(key, impl)
	end
	
	def [](key)
		raise StandardError, "nil is not a valid service" if key.nil?
		@instances[key] || instantiate(@classes[key], key)
	end
	
	def exec(cmd, params = {})
		instance = instantiate(cmd)
		options = AppKernel.instance_variable_get(:@options)[cmd]
		impl = AppKernel.instance_variable_get(:@commands)[cmd]
		raise ImplementationError.new(cmd) if impl.nil?
		for option in options do
			option.set(self, instance, params)
    end
		instance.instance_eval(&impl)
  end
	
	def resolves(type, resolver = nil, &block)
		@resolvers[type] = resolver ? resolver : InlineResolver.new(block)
  end
	
	def instantiate(cls, key = nil)
		return nil if cls.nil?
		deps = AppKernel.instance_eval {@dependencies[cls]}
		options = deps.inject({}) do |h, dep|
			value = self[dep.key]
			raise LinkageError.new(dep.key, cls) if value.nil?
			h[dep.field] = value
			h
		end
		instance = cls.new(options)
		return key.nil? ? instance  : @instances[key] = instance
	end
		
	class Service
		def self.inherited(subclass)
			subclass.class_eval do
				def initialize(options = {})
					for k,v in options do
						instance_variable_set("@#{k.to_s}".intern, v)
					end
				end
			end
      
			class << subclass
				def uses(key, options = {})
					raise ArgumentError.new, "nil is not a valid dependency" if key.nil?
					subclass = self
					AppKernel.instance_eval do
						@dependencies[subclass] << AppKernel::Dep.new(key, options)
					end
				end
        
				def hears(channel)
					subclass = self
					AppKernel.instance_eval do
						@listeners[subclass] << channel
					end
				end
			end
		end
	end
	
	class Command < Service  
		def self.inherited(subclass)
			super(subclass)
			class << subclass
				def option(name, options)
					command = self
					AppKernel.instance_eval do
						@options[command] << AppKernel::Option.new(name, options)
          end
				end
				
				def whenexecuted(&block)
					command = self
					AppKernel.instance_eval do
						@commands[command] = block
          end
        end
				
				def validate(&block)
					command = self
					AppKernel.instance_eval do
						@validators[command] = block
          end
        end
			end
		end
	end
	
	class InlineResolver
		
		def initialize(impl)
			@impl = impl
    end
		
		def resolve(kernel, spec)
			args = @impl.arity > 1 ? [kernel, spec] : [spec] 
			@impl.call(*args)
    end
  end
	
	class LinkageError < StandardError
		def initialize(key, cls)
			super("#{cls} has dependency '#{key}', but its implementation cannot be found")
		end
	end
	
	class ImplementationError < StandardError
		def initialize(cls)
			super("#{cls} does not specify what to do when executed. Use whenexecuted()")
    end
  end
end

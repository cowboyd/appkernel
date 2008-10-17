class AppKernel
	class Dep
		
		attr_reader :key, :field
		
		def initialize(key, options = {})
			@key = key
			@options = options
			@field = options[:field] || default_fieldname
			raise ArgumentError, "dependency '#{key.inspect}' does not have a valid field name. Try setting the :field option" unless valid_fieldname?(@field)
		end
		
		def valid_fieldname?(name)
			# try to set the field on a throw-away object, if it works, it must be a valid ivar name.
			begin
				field = "@#{name.to_s}"
				Object.new.instance_variable_set(field, 1)
			rescue NameError => e
				return false
			end
			return true
    end
		
		def default_fieldname
			@key.to_s.gsub(/\w[[:upper:]]/) {|m| "#{m[0,1]}_#{m[-1,1]}"}.downcase
    end
		
  end
	
	class Option
		
		def initialize(name, options = {})
			@name = name.to_s
			@symbol = @name.intern
			@ivar = "@#{name}".intern
			@options = options
			@type = options[:type] || String
    end
		
		def set(kernel, instance, params)
			spec = params[@name] || params[@symbol]
			if (spec.class == String && @type != String)
				value = resolve(kernel, spec)
			else
				value = spec
      end
			instance.instance_variable_set(@ivar, value)
    end
		
		def resolve(kernel, spec)
			resolvers = kernel.instance_variable_get(:@resolvers)
			resolver = resolvers[@type]
			
			raise ResolveError.new, "Don't know how to convert string '#{spec}' to type #{@type} while setting option '#{@name}'" if resolver.nil?
			resolver.resolve(kernel, spec)
    end
  end
	
	class ResolveError < StandardError;end
end

class AppKernel
	class PolymorphicHash < Hash
		def initialize(*args)
			super(*args)
			@equivalents = {}
    end
		
		def []=(k,v)
			super(k,v)
			if k.is_a?(Class)
				superclass = k.superclass
				while superclass
					@equivalents[superclass] = k
					superclass = superclass.superclass
        end
      end
    end
		
		def [](k)
			default = super(k)
			if default.nil? && k.is_a?(Class)
				if equivalent = @equivalents[k]
					super(equivalent) || nil
        end
			else
				default
      end
    end
	
  end
end

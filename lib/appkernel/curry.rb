
class AppKernel
  class Function
    def self.curry(options)
      Class.new(self).tap do |c|
        c.options.curry(@options, options)
      end
    end
    
    class Options
      def curry(parent, params)
        @presets.merge! parent.canonicalize([params], nil, false)        
        applied, unapplied = parent.options.values.partition {|o| @presets.has_key?(o.name)}
        unapplied.each do |option|
          ingest option
        end
        applied.each do |option|
          if option.required? && @presets[option.name].nil?
            raise AppKernel::OptionsError, "required option '#{option.name}' may not be nil"
          end
        end
      end
    end
  end
  

end
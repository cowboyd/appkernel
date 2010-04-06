
class AppKernel
  class Function
    def self.curry(options)
      Class.new(self).tap do |c|
        c.options.curry(@options, options)
      end
    end
    
    class Options
      def curry(parent, params)
        errors = Errors.new
        presets = parent.canonicalize([params], errors, false)
        raise ArgumentError, errors.all.join('; ') unless errors.empty?
        @presets.merge! presets
        applied, unapplied = parent.options.values.partition {|o| @presets.has_key?(o.name)}
        unapplied.each do |option|
          ingest option
        end
        applied.each do |option|
          if option.required? && @presets[option.name].nil?
            raise ArgumentError, "required option '#{option.name}' may not be nil"
          end
        end
      end
    end
  end
  

end
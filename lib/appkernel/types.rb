class Integer
  def self.to_option(spec)
    spec.to_i
  end
end

class Float
  def self.to_option(spec)
    spec.to_f
  end
end

class AppKernel
  
  Boolean = [TrueClass, FalseClass]
  
  def Boolean.to_option(o)
    case o.to_s.downcase.strip
    when "true", "t", "on", "y", "yes"
      true
    else
      false
    end
  end
end
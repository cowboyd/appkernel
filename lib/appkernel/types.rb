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

require 'net/http'
class URI::HTTP
  def self.to_option(spec)
    uri = URI.parse(spec)
    case uri.scheme
    when "http" then uri
    when nil then to_option("http://#{spec}")
    else
      if uri.host.nil?
        to_option("http://#{spec}")
      else
        raise "#{spec.inspect} is not a valid http url"
      end
    end
  end
end
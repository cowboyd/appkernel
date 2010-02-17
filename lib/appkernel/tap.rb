unless Object.method_defined?(:tap)
  class Object
    def tap
      yield self
      self
    end
  end
end
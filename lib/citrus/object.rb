class Object
  # A sugar method for creating grammars.
  #
  #     grammar :Calc do
  #     end
  #
  #     module MyModule
  #       grammar :Calc do
  #       end
  #     end
  #
  def grammar(name, &block)
    namespace = respond_to?(:const_set) ? self : Object
    namespace.const_set(name, Citrus::Grammar.new(&block))
  rescue NameError
    raise ArgumentError, 'Invalid grammar name: %s' % name
  end
end

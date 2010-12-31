module Citrus
  # Inclusion of this module into another extends the receiver with the grammar
  # helper methods in GrammarMethods. Although this module does not actually
  # provide any methods, constants, or variables to modules that include it, the
  # mere act of inclusion provides a useful lookup mechanism to determine if a
  # module is in fact a grammar.
  module Grammar
    # Creates a new anonymous module that includes Grammar. If a +block+ is
    # provided, it is +module_eval+'d in the context of the new module. Grammars
    # created with this method may be assigned a name by being assigned to some
    # constant, e.g.:
    #
    #     Calc = Citrus::Grammar.new {}
    #
    def self.new(&block)
      mod = Module.new { include Grammar }
      mod.module_eval(&block) if block
      mod
    end

    # Extends all modules that +include Grammar+ with GrammarMethods and
    # exposes Module#include.
    def self.included(mod)
      mod.extend(GrammarMethods)
      # Expose #include so it can be called publicly.
      class << mod; public :include end
    end
  end
end

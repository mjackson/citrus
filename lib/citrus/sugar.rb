require 'citrus'

[Citrus::Rule, String, Regexp, Symbol, Range, Array].each do |klass|
  klass.class_eval {
    def /(rule)
      Citrus::Choice.new([self, rule])
    end
  }
end

def grammar
  klass = Class.new(Citrus::Grammar)
  klass.module_eval(&Proc.new) if block_given?
  klass
end

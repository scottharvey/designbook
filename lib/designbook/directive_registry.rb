module Designbook
  class DirectiveRegistry
    Directive = Struct.new(:name, :renderer)

    def initialize
      @directives = {}
    end

    def register(name, &block)
      @directives[name.to_s] = Directive.new(name.to_s, block)
    end

    def render(name, argument, body, context:)
      directive = @directives[name.to_s]
      return nil unless directive

      case directive.renderer.arity
      when 0
        directive.renderer.call
      when 1
        directive.renderer.call(argument)
      when 2
        directive.renderer.call(argument, body)
      else
        directive.renderer.call(argument, body, context)
      end
    end
  end
end

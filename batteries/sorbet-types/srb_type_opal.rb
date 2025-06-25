module T
  module Sig
    def self.nilable(type)
      NilableType.new(type)
    end

    class NilableType
      attr_reader :type
      def initialize(type)
        @type = type
      end
    end

    module Sig
      def sig(&block)
        SignatureBuilder.new(&block)
      end
    end

    class SignatureBuilder
      def params(**kwargs)
        @params = kwargs
        self
      end

      def returns(type)
        @returns = type
        self
      end

      def to_proc
        ->(*args) {}
      end
    end
  end

  class Struct
    def self.inherited(subclass)
      subclass.instance_variable_set(:@props, {})
      subclass.extend(ClassMethods)
    end

    module ClassMethods
      def prop(name, type)
        @props[name] = type
        define_method(name) { instance_variable_get("@#{name}") }
        define_method("#{name}=") { |value| instance_variable_set("@#{name}", value) }
      end

      def props
        @props
      end
    end

    def initialize(**kwargs)
      self.class.props.each do |name, _|
        instance_variable_set("@#{name}", kwargs[name])
      end
    end

    def to_h
      self.class.props.keys.each_with_object({}) do |name, hash|
        hash[name] = send(name)
      end
    end
  end
end


require "file_utils"

class SorbetTypesBat


  def self.generate(ruby_src_dir : String)
    output_dir = "#{ruby_src_dir}/lib/sorbet-types"
    if !Dir.exists?(output_dir)
      Dir.mkdir_p(output_dir)
    end

    File.write("#{output_dir}/browser.rb", self.generate_browser_types)
    File.write("#{output_dir}/sorbet.rb", self.generate_opal_types)
  end

  def self.generate_browser_types : String
    <<-'RUBY'
      # typed: false
      require 'sorbet-runtime'
      require './lib/sorbet-types/sorbet.rb'

      module Browser
        module HTTP
          extend T::Sig

          # sig {params(url: String).returns(T.nilable(String))}
          def self.get(url)
          end

          sig {params(url: String, payload: T::Hash[String, String]).returns(T.nilable(String))}
          def self.post(url, payload)
          end
        end
      end
    RUBY
  end

  def self.generate_opal_types : String
    <<-'RUBY'
      # typed: false
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

          # The sig method needs to be directly in T::Sig, not nested
          def sig(&block)
            # Call the block which will invoke returns/params methods below
            yield if block_given?
            nil
          end

          # These methods are called from within sig blocks
          # They're no-ops for our stub implementation
          def returns(type)
            nil
          end

          def params(**kwargs)
            nil
          end

          def void
            nil
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
    RUBY
  end

end

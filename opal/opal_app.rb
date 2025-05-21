# typed: true

def Native(obj)
  # Implementation is provided by Opal
end

require './lib/sorbet_opal.rb'

require 'opal'
require 'native'
require 'promise'
require 'browser/setup/full'
require "await"

require "./lib/cafe.rb"


puts "Booting Opal..."
module App
  extend T::Sig

  @cafe = Cafe.new

  sig {params(name: String).returns(String)}
    def self.greet(name)
        "Hello #{name} from Ruby!"
    end

  sig {returns(T.anything)}
  def self.fetch_load_sets()
        @cafe.get("/api/load_sets")
    end

      def self.trigger_key(edge_name, payload)
        @cafe.post("/api/triggers/#{edge_name}", payload)
      end

      def self.maybe_trigger_key(value, type)
        puts value  # Ruby equivalent of console.log

        case type
        when "copy_paste"
          App.trigger_key(
            "copy_paste_trigger",
            { key: value }.to_json
          )
        when "cmd_plus"
          App.trigger_key(
            "cmd_plus_key_trigger",
            { keyCode: value }.to_json
          )
        when "shift_plus"
          App.trigger_key(
            "shift_plus_key_trigger",
            { keyCode: value }.to_json
          )
        when "option_plus"
          App.trigger_key(
            "option_plus_key_trigger",
            { keyCode: value }.to_json
          )
        when "shift_option_plus"
          App.trigger_key(
            "shift_option_plus_key_trigger",
            { keyCode: value }.to_json
          )
      end
    end

end
  
# Make the module available to JavaScript
require 'native'
$my_app = Native(App)

# works!
puts "Opal booted."

$document.ready do
    puts "Hello World from opal-browser"

end
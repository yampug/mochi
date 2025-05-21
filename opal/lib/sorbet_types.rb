# typed: true
require 'sorbet-runtime'
require './lib/sorbet_opal.rb'

module Browser
  module HTTP
    extend T::Sig
    sig {params(url: String).returns(T.nilable(String))}
    def self.get(url)
    end

    sig {params(url: String, payload: T::Hash[String, String]).returns(T.nilable(String))}
    def self.post(url, payload)
    end
  end
end
# typed: true
require './lib/sorbet_opal.rb'
require 'browser/setup/full'

class Cafe
  extend T::Sig

  def initialize

  end

  sig {params(url: String).returns(T.nilable(String))}
  def get(url)
    puts "[cafe] GET '#{url}'..."
    Browser::HTTP.get(url).then do |response|
      if response.status.code == 200
        response.text
      else
        raise "Error: #{response.status}"
      end
    end.fail do |error|
      "GET req. for '#{url}' failed: #{error}"
    end
  end

  sig {params(url: String, payload: T::Hash[String, String]).returns(T.nilable(String))}
  def post(url, payload)
    puts "[cafe] POST '#{url}' with payload '#{payload}'..."
    Browser::HTTP.post(url, payload) do |req|
      req.headers['Content-Type'] = 'application/json'
    end.then do |response|
      if response.status.code == 200
        response.text
      else
        raise "Error: #{response.status}"
      end
    end.fail do |error|
      "Request failed: #{error}"
    end
  end

end
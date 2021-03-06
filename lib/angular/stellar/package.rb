require 'json'

module Angular
  module Stellar
    JSON.parse(File.read(
      File.expand_path('../../../../package.json', __FILE__)
    )).each do |key, value|
      const_set(key.upcase, value)
    end
  end
end

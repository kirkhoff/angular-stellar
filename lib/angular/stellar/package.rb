require 'json'

module Angular
  module Stellar
    JSON.parse(File.read('package.json')).each do |key, value|
      const_set(key.upcase, value)
    end
  end
end

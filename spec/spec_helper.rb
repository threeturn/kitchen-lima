# frozen_string_literal: true

require "rspec"
require "kitchen"
require "kitchen/driver/lima"

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end

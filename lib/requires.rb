def kookaburra_require_glob(path_glob)
  Dir.glob(path_glob).each do |file|
    require file
  end
end

def kookaburra_require_all_relative_to(base_path, *relative_path_array)
  path = File.join(base_path, *relative_path_array.flatten)
  kookaburra_require_glob File.join(path, '*.rb')
end

# Require Capybara and Rack::Test
require 'rack/test'
require 'capybara'
Capybara.configure do |config|
  config.run_server     = false
  config.app_host       = 'http://www.example.com'
end


# Require the bits of ActiveSupport we use
require 'active_support/core_ext/class/attribute'
require 'active_support/hash_with_indifferent_access'

# Require specific paths from the bottom up.  Hooray for dependency graphs!
base = File.dirname(__FILE__)
kookaburra_require_all_relative_to base, %w[kookaburra ui_driver mixins]
kookaburra_require_all_relative_to base, %w[kookaburra ui_driver]
kookaburra_require_all_relative_to base, %w[kookaburra test_data]
kookaburra_require_all_relative_to base, %w[kookaburra]

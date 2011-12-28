require File.join(File.dirname(__FILE__), *%w[requires])

module Kookaburra
  class << self
    def drivers
      test_data = Kookaburra::TestData.new
      api       = api_driver(test_data)
      given     = given_driver(api)
      ui        = ui_driver(test_data)

      return {
        :api_driver   => RSpecRemovingProxy.new(api),
        :given_driver => RSpecRemovingProxy.new(given),
        :ui_driver    => RSpecRemovingProxy.new(ui),
      }
    end

  protected
    def api_driver(test_data)
      Kookaburra::APIDriver.new({
        :app       => capybara_app,
        :test_data => test_data,
      })
    end

    def given_driver(api_driver)
      Kookaburra::GivenDriver.new({
        :api_driver => api_driver,
      })
    end

    def ui_driver(test_data)
      Kookaburra::UIDriver.new({
        :browser   => capybara_browser,
        :test_data => test_data,
      })
    end

      def capybara_app
        Capybara.respond_to?(:app) ? Capybara.app : nil
      end

      def capybara_browser
        Capybara.respond_to?(:current_session) ? Capybara.current_session : nil
      end
  end
end

module Kookaburra
  class RSpecIntrusion < Exception
    def message
      "Please don't use RSpec expectations inside Kookaburra.  TERRIBLE THINGS WILL HAPPEN."
    end
  end
end

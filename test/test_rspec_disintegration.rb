require File.join(File.dirname(__FILE__), *%w[helper])

describe "RSpec (dis)integration" do
  # AnticipatedRSpecIntrusion = Class.new(Exception)

  before do
    Kernel.module_eval do
      unless defined?(UnwantedRSpecIntrusion)
        class UnwantedRSpecIntrusion < Exception
          def message
            "Client code was able to successfully call RSpec's #should or #should_not.  YOU LOSE."
          end
        end
      end
      def should(*_)
        raise UnwantedRSpecIntrusion
      end
      def should_not(*_)
        raise UnwantedRSpecIntrusion
      end
    end
  end

  after do
    Kernel.module_eval do
      if const_defined?(:RSpecExpectationSuccessfullyCalled)
        remove_const :RSpecExpectationSuccessfullyCalled
      end
      undef_method :should
      undef_method :should_not
    end
  end

  # TODO: remove this
  it 'checks sanity' do
    assert Kernel.methods.include?('should')
    assert Kernel.methods.include?('should_not')
  end

  describe Kookaburra::WorldSetup do
    class MeddlingComponent
      def poke_nose_into_rspec_where_it_doesnt_belong
        nil.should == nil
        raise "if you got here, something is messed up, yo"
      end
    end

    before do
      @world = Object.new
      @world.extend(Kookaburra::WorldSetup)
      @world.kookaburra_world_setup
      def @world.meddling_component
        MeddlingComponent.new
      end
      @world.instance_eval do
        @drivers[:api_driver] = Kookaburra::RSpecRemovingProxy.new(meddling_component)
      end
    end

    it "doesn't raise Kookaburra::RSpecIntrusion if you call the naughty method on the object itself" do
      # Calling the method on the object itself invokes Kernel#should
      assert_raises(UnwantedRSpecIntrusion) do
        @world.meddling_component.poke_nose_into_rspec_where_it_doesnt_belong
      end
    end

    it 'raises Kookaburra::RSpecIntrusion if you try to call #should inside the call to #api' do
      # Calling the method from the #api accessor raises an exception
      assert_raises(Kookaburra::RSpecIntrusion) do
        @world.api.poke_nose_into_rspec_where_it_doesnt_belong
      end
    end

    it "doesn't raise Kookaburra::RSpecIntrusion even after calling (i.e., Kernel#should gets redefined when you're done)" do
      begin
        @world.api.poke_nose_into_rspec_where_it_doesnt_belong
      rescue Kookaburra::RSpecIntrusion
        # do nothing
      end
    
      assert_raises(UnwantedRSpecIntrusion) do
        @world.meddling_component.poke_nose_into_rspec_where_it_doesnt_belong
      end
    end
  end
end

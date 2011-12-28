module Kookaburra
  class RSpecRemovingProxy
    instance_methods.each { |meth| undef_method(meth) unless meth =~ /^__/ }
    
    def initialize(proxied_object)
      @proxied_object = proxied_object
    end
    
    def method_missing(meth, *args, &block)
      __hide_rspec_methods(Kernel, :should, :should_not)
      @proxied_object.send(meth, *args, &block)
    ensure
      __show_rspec_methods(Kernel, :should, :should_not)
    end
  
  protected
    def __hide_rspec_methods(context, *method_names)
      method_names.each do |mname|
        rspec_mname = '__evil_evil_rspec_' + mname.to_s
        context.module_eval <<-RUBY
          alias :#{rspec_mname} :#{mname}
          define_method(:#{mname}) { raise Kookaburra::RSpecIntrusion }
        RUBY
      end
    end
    
    def __show_rspec_methods(context, *method_names)
      method_names.each do |mname|
        rspec_mname = '__evil_evil_rspec_' + mname.to_s
        context.module_eval <<-RUBY
          alias :#{mname} :#{rspec_mname}
          remove_method :#{rspec_mname}
        RUBY
      end
    end
  end
end

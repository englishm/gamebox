require 'actor'
require 'graphical_actor_view'
class ActorFactory
  constructor :input_manager, :sound_manager

  attr_accessor :mode_manager, :director
  
  # returns a hash of actor params
  def cached_actor_def(actor)
    @actor_cache ||= {}
    cached_actor = @actor_cache[actor]
    return cached_actor if cached_actor

    begin
      require actor.to_s
      require actor.to_s+"_view"
    rescue LoadError => ex
      # maybe its included somewhere else
    end
    model_klass_name = Inflector.camelize actor
    model_klass = Object.const_get model_klass_name
    
    begin
      view_klass = Object.const_get model_klass_name+"View"
    rescue Exception => ex
      # hrm...
    end
    
    actor_def = {
      :model_klass => model_klass,
      :view_klass => view_klass
    }
    @actor_cache[actor] = actor_def
    actor_def
  end

  
  def build(actor, level, opts={})
    actor_def = cached_actor_def actor

    basic_opts = {
      :level => level,
      :input => @input_manager,
      :sound => @sound_manager,
      :resources => level.resource_manager
    }
    merged_opts = basic_opts.merge(opts)

    model = actor_def[:model_klass].new merged_opts 

    view_klass = opts[:view]
    view_klass ||= actor_def[:view_klass]
    
    if model.is? :animated or model.is? :graphical or model.is? :physical
      view_klass ||= GraphicalActorView
    end
    view_klass.new @mode_manager.current_mode, model if view_klass
    
    # Register our new actor with the system
    @director.add_actor model
    
    model.show unless opts[:hide]

    return model
  end
end

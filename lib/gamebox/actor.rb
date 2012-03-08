# Actor represent a game object.
# Actors can have behaviors added and removed from them. Such as :physical or :animated.
# They are created and hooked up to their optional View class in Stage#create_actor.
class Actor
  include Kvo

  construct_with :stage, :input_manager, :director, :resource_manager, :wrapped_screen,
    :backstage, :sound_manager
  public :stage, :input_manager, :director, :resource_manager, :wrapped_screen,
    :backstage, :sound_manager
  
  attr_accessor :behaviors, :alive, :opts, :visible, :actor_type

  # TODO change alive and visible to be KVO
  kvo_attr_accessor :x, :y, :alive, :visible

  can_fire_anything

  DEFAULT_PARAMS = {
    :x => 0,
    :y => 0,
  }.freeze

  def configure(opts={}) # :nodoc:
    @opts = DEFAULT_PARAMS.merge opts
    self.x = @opts[:x]
    self.y = @opts[:y]

    @actor_type = @opts[:actor_type]
    self.alive = true

    @behaviors = {}

    # add our classes behaviors and parents behaviors
    klass = self.class
    actor_klasses = []
    while klass != Actor
      actor_klasses << klass
      klass = klass.superclass
    end

    behavior_defs = {}
    ordered_behaviors = []
    
    actor_klasses.reverse.each do |actor_klass|
      actor_behaviors = actor_klass.behaviors.dup
      actor_behaviors.each do |behavior|

        behavior_sym = behavior.is_a?(Hash) ? behavior.keys.first : behavior

        ordered_behaviors << behavior_sym unless ordered_behaviors.include? behavior_sym
        behavior_defs[behavior_sym] = behavior
      end
    end

    ordered_behaviors.each do |behavior|
      is behavior_defs[behavior] unless is? behavior
    end
    setup
  end

  # Called at the end of actor/behavior initialization. To be defined by the
  # child class.
  def setup
  end

  # Is the actor still alive?
  def alive?
    self.alive
  end

  def screen
    wrapped_screen
  end

  # Tells the actor's Director that he wants to be removed; and unsubscribes
  # the actor from all input events.
  def remove_self
    self.alive = false
    fire :remove_me
    input_manager.unsubscribe_all self
  end

  # Does this actor have this behavior?
  def is?(behavior_sym)
    !@behaviors[behavior_sym].nil?
  end

  # Adds the given behavior to the actor. Takes a symbol or a Hash.
  #  act.is(:shootable) or act.is(:shootable => {:range=>3})
  #  this will create a new instance of Shootable and pass
  #  :range=>3 to it
  #  Actor#is does try to require 'shootable' but will not throw an error if shootable cannot be required.
  def is(behavior_def)
    if behavior_def.is_a?(Hash)
      behavior_sym = behavior_def.keys.first
      behavior_opts = behavior_def.values.first
    else
      behavior_sym = behavior_def
      behavior_opts = {}
    end
    klass = Object.const_get Inflector.camelize(behavior_sym)
    @behaviors[behavior_sym] = klass.new self, behavior_opts
  end

  # removed the behavior from the actor.
  def is_no_longer(behavior_sym)
    behavior = @behaviors.delete behavior_sym
    behavior.removed if behavior
  end

  # Calls update on all the actor's behaviors.
  def update_behaviors(time)
    for behavior in @behaviors.values
      behavior.update time
    end
  end

  # Creates a new actor and returns it. (This actor will automatically be added to the Director.
  def spawn(type, args={})
    stage.spawn type, args
  end

  # to be defined in child class
  def update(time)
    # TODO maybe use a callback list for child classes
    update_behaviors time
  end

  def hide
    fire :hide_me if visible?
    self.visible = false
  end

  def show
    fire :show_me unless visible?
    self.visible = true
  end

  def visible?
    self.visible
  end

  def viewport
    stage.viewport
  end

  def to_s
    "#{self.class.name}:#{self.object_id} [#{self.x},#{self.y}] with behaviors\n#{self.behaviors.keys}"
  end

  class << self
    def behaviors
      @behaviors ||= []
    end

    def has_behaviors(*args)
      @behaviors ||= []
      for a in args
        if a.is_a? Hash
          for k,v in a 
            h = {}
            h[k]=v
            @behaviors << h
          end
        else
          @behaviors << a
        end
      end
      @behaviors
    end

    def has_behavior(*args)
      has_behaviors *args
    end
  end
end

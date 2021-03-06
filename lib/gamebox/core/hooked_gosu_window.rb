module GosuWindowAPI
  def initialize(width, height, fullscreen)
    super(width, height, fullscreen)
  end

  def update
    millis = Gosu::milliseconds

    # ignore the first update
    if @last_millis
      if millis > @last_millis
        fire :update, (millis - @last_millis)
      else
        # we rolled over, we drop a few millis because Gosu doesn't publish max
        # millis
        fire :update, millis
      end
    end

    @last_millis = millis
  end

  def draw
    fire :draw
  end

  # in gosu this captures mouse and keyboard events
  def button_down(id)
    fire :button_down, id
  end

  def button_up(id)
    fire :button_up, id
  end

  attr_accessor :needs_cursor
  alias :needs_cursor? :needs_cursor
end

class HookedGosuWindow < Window
  extend Publisher
  include GosuWindowAPI
  can_fire :update, :draw, :button_down, :button_up

end

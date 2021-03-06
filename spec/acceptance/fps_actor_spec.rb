require 'helper'

describe "Using fps actor", acceptance: true do
  it 'draws and updates the fps label' do
    game.stage do |stage| # instance of TestingStage
      @fps = create_actor :fps, font_name: 'arial', font_size: 20
    end

    game.should have_actor(:fps)
    game.should have_actor(:label)
    draw
    see_text_drawn "", in: arial_20

    Gosu.stubs(:fps).returns(99)
    draw
    see_text_drawn "", in: arial_20

    update 100
    draw
    see_text_drawn "99", in: arial_20

    remove_fps

    game.should_not have_actor(:fps)
    game.should_not have_actor(:label)

    pending "check color of drawn fonts"

  end

  let!(:arial_20) { mock_font('arial', 20) }

  def remove_fps
    game.current_stage.instance_variable_get("@fps").remove
    # TODO is this needed?
    update 1
  end

end


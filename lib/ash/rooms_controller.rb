module Ash
  class RoomsController
    def initialize(view)
      @view = view
      @view.render
    end

    def relayout(layout)
      @view.relayout(layout)
      @view.render
    end

    def update
      i = 1
      buffer = []
      Ash.app.available_rooms.each do |(account, rooms)|
        rooms.each do |room|
          buffer << ["[#{i}] #{account.name}: #{room.name}", { active: room == Ash.app.current_room } ]
          i += 1
        end
      end
      @view.buffer = buffer
      @view.render
    end
  end
end
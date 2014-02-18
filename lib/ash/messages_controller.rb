module Ash
  class MessagesController
    def initialize(view)
      @view = view
      @messages = @view.buffer = []
      @view.render
    end

    def relayout(layout)
      @view.relayout(layout)
      @view.render
    end

    def clear
      @messages = @view.buffer = []
      @view.render
    end

    def scroll_down
      @view.scroll(+1)
      @view.render
    end

    def scroll_up
      @view.scroll(-1)
      @view.render
    end

    # DEPRECATE
    def add_ruled_system_message(msg)
      add_message msg, system: true, ruled: true
    end

    def add_message(msg, opts = {})
      @messages << [msg, opts]
      @view.scroll_to_bottom
      @view.render
    end
  end
end

require 'ash/view'

module Ash
  class ScrollableView < View
    def initialize(*)
      super
      @scroll_y = 0
    end

    def scroll(delta)
      new_scroll_y = @scroll_y + delta
      return unless new_scroll_y >= 0
      return unless new_scroll_y < content_lines.size
      return unless new_scroll_y <= max_scroll_y
      @scroll_y = new_scroll_y
    end

    def scroll_to_bottom
      @scroll_y = max_scroll_y
    end

    protected

    def content_lines_for_render
      content_lines[@scroll_y, lines]
    end

    private

    def max_scroll_y
      if content_lines.size > lines
        content_lines.size - lines
      else
        0
      end
    end
  end
end

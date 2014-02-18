module Ash
  class View
    attr_reader :win
    attr_accessor :buffer

    def initialize(parent_window, opts = {})
      @win = parent_window.subwin(*opts.values_at(:height, :width, :top, :left))
      @win.scrollok(false)
      @buffer = []
    end

    def relayout(layout)
      @win.move(*layout.values_at(:top, :left))
      @win.resize(*layout.values_at(:height, :width))
      # render
    end

    def lines
      @win.maxy
    end

    def cols
      @win.maxx
    end

    def render
      @win.clear

      render_rows = content_lines_for_render.dup

      if render_rows.size < lines
        (lines - render_rows.size).times { render_rows << [nil, {}] }
      end

      render_rows[0, lines].each_with_index do |(str, opts), idx|
        @win.setpos idx, 0
        render_line str, opts, idx
      end

      @win.refresh
    end

    # def resize
    #   #@window.move(0, 0)
    #   @win.resize(lines, cols)
    #   @win.refresh
    #   repaint
    # end

    protected

    def render_line(str, opts, idx)
      return if str.nil?
      @win.addstr str
    end

    def content_lines_for_render
      content_lines
    end

    def content_lines
      max_length = cols
      line_num = 0
      content = []

      buffer.each do |(msg, opts)|
        max_line_length_enforced_str(msg, max_length).split(/\n/).each_with_index do |line, idx|
          str = ""
          str << line
          content << [str, opts]
          line_num += 1
        end
      end

      content
    end

    def max_line_length_enforced_str(str, max_length)
      str.gsub(/([^\n]{0,#{max_length}}(\b|$))/m, "\\1\n")
    end
  end
end

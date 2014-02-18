require 'ash/view'

module Ash
  class RoomsView < View
    protected

    def render_line(str, opts, idx)
      @win.addstr "| "
      return if str.nil?

      if opts[:active]
        @win.attron Curses.color_pair(2) | Curses::A_BOLD do
          @win.addstr str
        end
      else
        @win.addstr str
      end
    end

    def content_lines
      max_length = cols - 2
      line_num = 0
      content = []

      buffer.each do |(msg, opts)|
        max_line_length_enforced_str(msg, max_length).split(/\n/).each_with_index do |line, idx|
          str = ''
          str << line
          content << [str, opts]
          line_num += 1
        end
      end

      content
    end
  end
end

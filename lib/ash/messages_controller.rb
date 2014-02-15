module Ash
  class MessagesController
    def initialize(parent_window)
      @window = parent_window.subwin(lines, Curses.cols, 0, 0)
      #@window.setscrreg(0, Curses.lines - 1)
      @window.scrollok false
      @buffer_lines = []
      @scroll_y = 0

      # TODO link/photo clicks
      # window = @window
      # Curses.mousemask [Curses::ALL_MOUSE_EVENTS]
      # Thread.new do
      #   loop do
      #     char = Curses.getch
      #     if char == Curses::KEY_MOUSE
      #       add_message Curses.get_mouse.inspect, system: true
      #     else
      #       add_message "event", system: true
      #     end
      #   end
      # end
    end

    def redraw
      @window.resize(lines, Curses.cols)
      @window.refresh
      repaint
    end

    def clear
      @buffer_lines = []
      @scroll_y = 0
      repaint
    end

    def scroll_down
      return unless (@scroll_y + lines) < @buffer_lines.size
      @scroll_y += 1
      repaint
    end

    def scroll_up
      return unless @scroll_y > 0
      @scroll_y -= 1
      repaint
    end

    def add_ruled_system_message(msg)
      add_message msg, system: true, ruled: true
    end

    def add_message(msg, opts = {})
      # scroll to bottom
      @scroll_y = [@scroll_y, @buffer_lines.size - lines].max

      # TODO should calc/recalc on window resize, since line length can change
      max_line_length_enforced_msg = msg.gsub(/([^\n]{0,#{Curses.cols - 4}}(\b|$))/m, "\\1\n").gsub(/\n{2,}/, "\n\n").strip

      max_line_length_enforced_msg.split(/\n/).each_with_index do |line, idx|
        str = ""

        if opts[:person]
          person_prefix = "#{opts[:person].initials.rjust(2, '_')}: "

          if idx == 0
            str << person_prefix
          else
            str << " " * person_prefix.size
          end
        end

        str << line

        @buffer_lines << [str, opts]
        @scroll_y += 1 if @buffer_lines.size > lines
      end

      repaint
    end

    def repaint
      scroll_y = @scroll_y

      @window.clear

      @buffer_lines[scroll_y, lines].each_with_index do |(str, opts), idx|
        @window.setpos idx, 0

        line_num = idx + scroll_y
        debug_prefix = "[#{scroll_y.to_s.rjust(3)}, #{line_num.to_s.rjust(3)}]: "

        if Ash.app.debug
          @window.addstr debug_prefix
        end

        if opts[:system]
          if opts[:ruled]
            rule_char = '—'
            str = "#{rule_char * 3} #{str} "
            post_rule_size = Curses.cols - str.size
            post_rule_size -= debug_prefix.size if Ash.app.debug
            str << rule_char * post_rule_size
          end

          @window.attron Curses.color_pair(2) | Curses::A_BOLD do
            @window.addstr str
          end
        elsif opts[:person] == Ash.app.current_account.me
          @window.attron Curses.color_pair(1) | Curses::A_NORMAL do
            @window.addstr str
          end
        else
          @window.addstr str
        end
      end

      @window.refresh
    end

    private

    def lines
      Curses.lines - 2
    end
  end
end

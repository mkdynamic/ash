require 'ash/scrollable_view'

module Ash
  class MessagesView < ScrollableView
    protected

    def render_line(str, opts, idx)
      return if str.nil?

      if opts[:system]
        @win.attron Curses.color_pair(2) | Curses::A_BOLD do
          @win.addstr str
        end
      elsif Ash.app.current_account && opts[:person] == Ash.app.current_account.me
        @win.attron Curses.color_pair(1) | Curses::A_NORMAL do
          @win.addstr str
        end
      else
        @win.addstr str
      end
    end

    def content_lines
      max_length = cols - 4
      max_length -= 12 if Ash.app.debug
      line_num = 0
      scroll_y = @scroll_y
      content = []

      buffer.each do |(msg, opts)|
        max_line_length_enforced_str(msg, max_length).gsub(/\n{2,}/, "\n\n").strip.split(/\n/).each_with_index do |line, idx|
          str = ""

          if Ash.app.debug
            debug_prefix = "[#{scroll_y.to_s.rjust(3)}, #{line_num.to_s.rjust(3)}]: "

            str << debug_prefix
          end

          if opts[:person]
            person_prefix = "#{opts[:person].initials.rjust(2, '_')}: "

            if idx == 0
              str << person_prefix
            else
              str << " " * person_prefix.size
            end
          end

          str << line

          if opts[:ruled]
            rule_char = '—'
            str = "#{rule_char * 3} #{str} "
            post_rule_size = cols - str.size
            str << rule_char * post_rule_size
          end

          content << [str, opts]
          line_num += 1
        end
      end

      content
    end
  end
end

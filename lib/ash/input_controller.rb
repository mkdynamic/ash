require 'thread'

module Ash
  class InputController
    def initialize(view, messages)
      @prompt = ">"
      @cursor = { x: 0, y: 0 }
      @window = view.win
      @view = view
      @window.addstr @prompt
      @window.setpos @cursor[:y], @cursor[:x] + @prompt.size + 1

      @messages = messages
      @history_index = 0
      @history = []

      @buffer = ""
      @commands = {
        27 => {
          127 => :word_backspace_buffer!,
          98 => :cursor_back_word,
          102 => :cursor_forward_word,
          91 => {
            65 => :history_up,
            66 => :history_down,
            67 => :cursor_forward,
            68 => :cursor_back
          }
        },
        21 => :scroll_up,
        4 => :scroll_down,
        127 => :backspace_buffer!,
        10 => :process_buffer!,
        3 => :quit!,
        1 => :cursor_to_start,
        5 => :cursor_to_end,
        Curses::KEY_RESIZE => :command_resize
      }

      @update_queue = Queue.new
      @update_thread = Thread.new do
        loop do
          char = @update_queue.pop
          next if char.nil?
          handle char, @commands
          update
        end
      end
    end

    def command_resize
      Ash.app.resize
    end

    def relayout(layout)
      @view.relayout(layout)
      update
    end

    def debug(msg)
      if Ash.app.debug
        @messages.add_message "[DEBUG] #{msg}", system: true
      end
    end

    def handle(char, hash)
      debug "CH: #{char.ord}"

      if hash.include?(char.ord)
        value = hash[char.ord]
        if Hash === value
          char = @window.getch
          if value.include?(char.ord)
            handle char, value
          else
            handle char, @commands
          end
        else
          send value
        end
      else
        @buffer = @buffer[0...@cursor[:x]].to_s + char.to_s + @buffer[@cursor[:x]..-1].to_s
        @history[@history_index] = @buffer
        @cursor[:x] += char.to_s.size
      end
    end

    def focus
      @window.refresh
    end

    def update
      @window.clear
      @window.addstr @prompt + ' ' + @buffer
      @window.setpos @cursor[:y], @cursor[:x] + @prompt.size + 1
      @window.refresh
    end

    def quit!
      exit
    end

    def scroll_up
      @messages.scroll_up
    end

    def scroll_down
      @messages.scroll_down
    end

    def word_backspace_buffer!
      if @cursor[:x] > 0
        txt = @buffer[0..@cursor[:x]-1].to_s
        i = txt.rindex(/\b[^\s*$]/) || 0
        size = txt.size - i
        @buffer = @buffer[0...i].to_s + @buffer[@cursor[:x]..-1].to_s
        @cursor[:x] -= size
      end
    end

    def cursor_forward_word
      if @cursor[:x] < @buffer.size
        txt = @buffer[@cursor[:x]..-1].to_s
        i = txt.index(/[^^\s*]\b/) || txt.size - 1
        size = i + 1
        @cursor[:x] += size
      end
    end

    def cursor_back_word
      if @cursor[:x] > 0
        txt = @buffer[0..@cursor[:x]-1].to_s
        i = txt.rindex(/\b[^\s*$]/) || 0
        size = txt.size - i
        @cursor[:x] -= size
      end
    end

    def history_down
      if @history_index < @history.size - 1
        @history_index += 1
        @buffer = @history[@history_index]
        cursor_to_end
      end
    end

    def history_up
      if @history_index > 0
        @history_index -= 1
        @buffer = @history[@history_index]
        cursor_to_end
      end
    end

    def cursor_to_end
      @cursor[:x] = @buffer.size
    end

    def cursor_to_start
      @cursor[:x] = 0
    end

    def cursor_back
      @cursor[:x] -= 1 if @cursor[:x] > 0
    end

    def cursor_forward
      @cursor[:x] += 1 if @cursor[:x] < @buffer.size
    end

    def backspace_buffer!
      if @cursor[:x] > 0
        @buffer = @buffer[0...@cursor[:x]-1].to_s + @buffer[@cursor[:x]..-1].to_s
        @cursor[:x] -= 1
      end
    end

    def command_people
     if Ash.app.current_room
        @messages.add_ruled_system_message "People in #{Ash.app.current_room.name}"
        Ash.app.current_room.people.values.sort_by(&:name).each do |person|
          @messages.add_message "- #{person.initials.rjust(2, '_')}: #{person.name}", system: true
        end
      else
        @messages.add_message "No current room.", system: true
      end
    end

    def command_clear
      @messages.clear
    end
    alias_method :command_cls, :command_clear

    def command_quit
      exit 0
    end
    alias_method :command_exit, :command_quit

    def command_debug_on
      Ash.app.debug = true
    end

    def command_debug_off
      Ash.app.debug = false
    end

    def command_rooms
      @messages.add_ruled_system_message "Rooms"
      i = 1
      Ash.app.available_rooms.each do |(account, rooms)|
        rooms.each do |room|
          @messages.add_message "[#{i}] #{account.name}: #{room.name}", system: true
          i += 1
        end
      end
    end

    def command_room(i = nil)
      if i
        i = i.to_i
        @messages.add_message "Switching room...", system: true
        account, room = Ash.app.available_rooms.map { |(account, rooms)| rooms.map { |room| [account, room] } }.flatten(1)[i - 1]
        Ash.app.switch_to_room(account, room)
      else
        if Ash.app.current_room
          @messages.add_message "Room is #{Ash.app.current_room.name}.", system: true
        else
          @messages.add_message "No current room.", system: true
        end
      end
    end

    def command_help
      commands = methods.select { |m| m.to_s =~ /^command_.+$/ }.map { |m| m.to_s.sub(/^command_/, '') }.sort
      @messages.add_message "Available commands: #{commands.join(', ')}", system: true
    end

    def process_buffer!
      if @buffer[0] == ':'
        command_name, *args = @buffer[1..-1].to_s.split(/\s+/)
        method_name = "command_#{command_name}"
        if respond_to?(method_name)
          begin
            send method_name, *args
          rescue ArgumentError => e
            #@messages.add_message "Command error: #{e}"
            raise e
          end
        else
          @messages.add_message "No command #{command_name.inspect} found!", system: true
        end
      elsif Ash.app.current_account.nil?
        @messages.add_message "No current room!", system: true
      else
        on_message = @on_message
        buffer = @buffer
        if on_message && !buffer.empty?
          @messages.add_message @buffer, person: Ash.app.current_account.me
          Thread.new do
            on_message.call buffer
          end
        end
      end
      @cursor = { x: 0, y: 0 }
      @window.setpos @cursor[:y], @cursor[:x] + @prompt.size + 1
      @window.clrtoeol
      @buffer = ""
      @history.reject!(&:empty?)
      @history << @buffer
      @history_index = @history.size - 1
    end

    def on_message=(callable)
      @on_message = callable
    end

    def listen
      loop do
        #@update_queue << @window.getch

        char = @window.getch#@update_queue.pop
          next if char.nil?
          handle char, @commands
          update
      end
    end
  end
end

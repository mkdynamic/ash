# encoding: UTF-8

require 'yaml'
require 'ash/view'
require 'ash/messages_view'
require 'ash/rooms_view'
require 'ash/messages_controller'
require 'ash/input_controller'
require 'ash/rooms_controller'
require 'ash/account'

module Ash
  class App
    attr_reader :current_account, :current_room
    attr_accessor :debug

    def initialize
    end

    def calc_layout
      window_width, window_height = Curses.cols, Curses.lines
      rooms_width = 50
      messages_width = window_width - rooms_width
      layout = {}
      layout[:input] = { top: window_height - 1, left: 0, height: 1, width: window_width }
      layout[:messages] = { top: 0, left: 0, height: window_height - 2, width: messages_width }
      layout[:rooms] = { top: 0, left: messages_width, height: window_height - 2, width: rooms_width }
      layout
    end

    def run
      Thread.abort_on_exception = true unless ENV['ASH_ENV'] == 'release'

      Curses.init_screen
      Curses.start_color
      Curses.use_default_colors
      #Curses.init_color Curses::COLOR_BLUE, 1000, 0, 0
      Curses.init_pair 1, Curses::COLOR_WHITE, -1 # -1 is transparent/none
      Curses.init_pair 2, Curses::COLOR_WHITE, Curses::COLOR_BLUE
      Curses.noecho
      Curses.raw
      @window = Curses.stdscr

      layout = calc_layout
      input_view = View.new(@window, layout[:input])
      messages_view = MessagesView.new(@window, layout[:messages])
      rooms_view = RoomsView.new(@window, layout[:rooms])

      @rooms = RoomsController.new(rooms_view)
      @messages = MessagesController.new(messages_view)
      @input = InputController.new(input_view, @messages)

      Curses.refresh

      @input.on_message = lambda do |message|
        @current_room.speak message.to_s
      end

      #default_account = available_accounts.first
      #default_room = default_account.rooms.first
      #switch_to_room default_account, default_room

      @input.listen
    ensure
      disconnect_current_room
      Curses.close_screen rescue nil
      puts "Cheerio"
    end

    def resize
      @window.clear
      @window.refresh
      layout = calc_layout
      @rooms.relayout(layout[:rooms])
      @messages.relayout(layout[:messages])
      @input.relayout(layout[:input])
    end

    def available_accounts
      @available_accounts ||= config[:accounts].map { |(name, config)| Account.new(name, config[:provider], config) }
    end

    def available_rooms
      @available_rooms ||= available_accounts.inject({}) { |memo, (account)| memo[account] = account.rooms; memo }
    end

    def switch_to_room(account, room)
      disconnect_current_room
      @current_account = account
      @current_room = room
      @current_room.on_message = lambda do |message, opts|
        @messages.add_message message, opts
        if notify_regexp && !opts[:silent] && message.match(notify_regexp)
          Thread.new { system "afplay /System/Library/Sounds/Purr.aiff" }
        end
        @input.focus
      end
      @current_room.connect
      @rooms.update
      @messages.add_ruled_system_message "Entered room #{@current_room.name.inspect}"
      @current_room.load_recent
      @room_listener = Thread.new { @current_room.listen }
    end

    def disconnect_current_room
      @room_listener and @room_listener.exit
      @current_room and @current_room.disconnect rescue nil
    end

    def notify_regexp
      config && config[:notify] && config[:notify][:regexp]
    end

    def config
      @config ||= begin
        config_path = File.expand_path("~/.ash.yml", __FILE__)
        YAML::load_file(config_path)
      end
    end
  end
end

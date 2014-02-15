# encoding: UTF-8

require 'yaml'
require 'ash/messages_controller'
require 'ash/input_controller'
require 'ash/account'

module Ash
  class App
    attr_reader :current_account, :current_room
    attr_accessor :debug

    def initialize
    end

    def run
      Thread.abort_on_exception = true unless ENV['ASH_ENV'] == 'release'

      Curses.init_screen
      Curses.start_color
      Curses.use_default_colors
      #Curses.init_color Curses::COLOR_BLUE, 1000, 0, 0
      Curses.init_pair 1, 27, -1
      Curses.init_pair 2, 15, 27
      Curses.noecho
      Curses.raw

      @window = Curses.stdscr
      @messages = MessagesController.new(@window)
      @input = InputController.new(@window, @messages)
      Curses.refresh

      Signal.trap("SIGWINCH") do
        @messages.redraw
        @input.redraw
      end

      @input.on_message = lambda do |message|
        @current_room.speak message.to_s
      end

      default_account = available_accounts.first
      default_room = default_account.rooms.first
      #switch_to_room default_account, default_room

      input_listener = Thread.new { @input.listen }
      input_listener.join
    ensure
      disconnect_current_room
      Curses.close_screen rescue nil
      puts "Cheerio"
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
      @messages.add_ruled_system_message "Entering room #{@current_room.name.inspect}"
      @current_room.connect
      @room_listener = Thread.new { @current_room.listen }
      @current_room.load_recent
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

require 'twitter/json_stream'
require 'ash/room'
require 'ash/person'

module Ash
  module Providers
    class Campfire
      attr_reader :me

      def initialize(config)
        @tinder = Tinder::Campfire.new config[:subdomain], :token => config[:token]
        me = @tinder.me
        @me = Person.new(me.id, me.name)
      end

      def rooms
        @tinder.rooms.map do |room|
          Ash::Providers::Campfire::Room.new(room, me)
        end
      end

      class Room < Ash::Room
        attr_reader :me

        def initialize(tinder_room, me)
          @tinder_room = tinder_room
          @me = me
          @name = tinder_room.name
        end

        def people
          @people ||= @tinder_room.users
            .map { |user| user[:id] == @me.id ? @me : Person.new(user[:id], user[:name]) }
            .inject({}) { |memo, person| memo[person.id] = person; memo }
        end

        def connect
        end

        def disconnect
          @tinder_room.stop_listening
        end

        def on_message=(callable)
          @on_message = callable
        end

        def listen
          # either poll or stream to listen for messages
          @tinder_room.listen do |m|
            if m && m.is_a?(Hash) && m[:user] && m[:user][:id] != me.id && m[:body] && !m[:body].empty?
              people[m[:user][:id]] ||= Person.new(m[:user][:id], m[:user][:name])
              @on_message.call m[:body], person: people[m[:user][:id]]
            end
          end
        rescue HTTP::Parser::Error
          listen
        end

        def load_recent
          @tinder_room.transcript.each do |m|
            if m && m.is_a?(Hash) && m[:user] && m[:body] && !m[:body].empty?
              people[m[:user][:id]] ||= Person.new(m[:user][:id], m[:user][:name])
              @on_message.call m[:body], person: people[m[:user][:id]], silent: true
            end
          end
        end

        def speak(msg)
          if msg.match '/play'
            @tinder_room.play msg.sub('/play ', '').strip
          else
            @tinder_room.speak msg
          end
        end
      end
    end
  end
end

require 'twitter/json_stream'
require 'ash/room'
require 'ash/person'

module Ash
  module Providers
    class Slack
      attr_reader :me
      attr_reader :token

      def base_url
        "https://slack.com/api/"
      end

      def api_url(method, params="")
        base_url + method + "?token=#{@token}#{params}"
      end

      def initialize(config)
        #@tinder = Tinder::Campfire.new config[:subdomain], :token => config[:token]
        @token = config[:token]
        @team = config[:team]
        @me = Person.new(config[:user_id], config[:username])
      end

      def rooms
        #channels
        channels = (HTTParty.get(api_url("channels.list"))['channels'].map { |room|
          Ash::Providers::Slack::Room.new(room, me, self)
        }.find_all{|e| e})

        #groups
        channels.concat (HTTParty.get(api_url("groups.list"))['groups'].map { |room|
          Ash::Providers::Slack::Group.new(room, me, self)
        }.find_all{|e| e})
      end

      class Room < Ash::Room
        attr_reader :me, :slack

        def initialize(json_channel, me, service)
          @json_channel = json_channel
          @me = me
          @name = json_channel['name']
          @slack = service
        end

        def people
          response = HTTParty.get(slack.api_url("users.list"))

          @people ||= response['members']
            .map { |user| user['id'] == @me.id ? @me : Person.new(user['id'], user['name']) }
            .inject({}) { |memo, person| memo[person.id] = person; memo }
        end

        def connect
        end

        def disconnect
        end

        def on_message=(callable)
          @on_message = callable
        end

        def listen
        end

        def load_recent
          method_name = (self.kind_of? Group) ? "groups.history" : "channels.history"
          url = slack.api_url(method_name, "&channel=#{@json_channel['id']}")
          response = HTTParty.get(url)
          if response['messages']
            response['messages'].reverse.each do |m|
              if m['user']
                #need to get name
                people[m['user']] ||= Person.new(m['user'], m['user'])
                if m['text']
                  @on_message.call m['text'], person: people[m['user']], silent: true, no_repaint: true
                end
              end
            end
          end
        end

        def speak(msg)
          msg = msg.gsub('&', '&amp;')
          msg = msg.gsub('<', '&lt;')
          msg = msg.gsub('>', '&gt;')
          HTTParty.post(slack.base_url + 'chat.postMessage', :body => {:token => slack.token, :channel => @json_channel['id'], :text => msg, :usernname => me.name})
        end
      end

      class Group < Slack::Room
      end

    end
  end
end

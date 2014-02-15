# Represents an account with some +Provider+ (Campfire, AIM, Google Talk etc.)
#
# An account has many +Rooms+, which may be groups or individual contacts.
#
require 'ash/room'
require 'ash/person'

module Ash
  class Account
    attr_reader :name, :provider
    private :provider

    def initialize(name, provider, config)
      @name = name
      require "ash-#{provider}"
      klass = eval("Ash::Providers::#{provider.capitalize}")
      @provider = klass.new(config)
    end

    def me
      provider.me
    end

    def rooms
      provider.rooms
    end
  end
end

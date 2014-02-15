require "rubygems"
require "bundler/setup"
Bundler.require
require "curses"

require 'ash-campfire'

require 'ash/app'
module Ash
  def self.app
    @app
  end

  def self.launch
    @app = App.new
    @app.run
  end
end

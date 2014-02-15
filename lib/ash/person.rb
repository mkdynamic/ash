module Ash
  class Person
    # TODO move to config
    CUSTOM_INITIALS = { 'Mark Dodwell' => 'mk' }

    attr_reader :name, :id

    def initialize(id, name)
      @id = id
      @name = name
    end

    def initials
      if CUSTOM_INITIALS[name]
        CUSTOM_INITIALS[name]
      else
       letters = name.split(/\s+/).map { |s| s[0] }.map(&:downcase)
       "#{letters.shift}#{letters.pop}"
      end
    end
  end
end

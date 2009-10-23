require 'rubygems'
require 'open-uri'
require 'hpricot'

module Pentabarf
    class Conference
        attr_reader :title, :subtitle, :venue, :city, :start, :end, :days,
                    :release, :day_change, :timeslot_duration, :events
        def initialize(args)
            uri      = args[:uri]
            fallback = args[:fallback]
            puts fallback
            h = 
            begin
                h = open(uri) { |f| Hpricot(f) }
            rescue
                STDERR.puts "warning: could not open #{uri}"
                open(fallback) { |f| Hpricot(f) }
            end

            # set attributes from the corresponding XML part
            conf = h.at('//schedule/conference')
            conf.children.select { |c| c.class == Hpricot::Elem }.each do |c|
                puts c.inner_text
                puts c.name
                self.instance_variable_set "@#{c.name}".to_sym, c.inner_text
            end
            puts self.title
            puts self.subtitle
        end
    end
    
    class Event
        include Comparable
        attr_reader :id, :date, :start, :duration, :room, :tag, :title,
                    :subtitle, :track, :type, :language, :abstract,
                    :description, :persons

        def <=>(other)
            # compare date first
            if (self.date <=> other.date) != 0 then
                return self.date <=> other.date
            end
            # then starting time
            if (self.start <=> other.start) != 0 then
                return self.start <=> other.start
            end
            # the room number
            self.room <=> other.room
        end
    end

    class Person
        attr_reader :id, :name
    end
end

conf = Pentabarf::Conference.new(:uri => 'http://fwef8uwe9fw',
                                 :fallback => 'sample_schedule.xml')

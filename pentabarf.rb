require 'rubygems'
require 'open-uri'
require 'hpricot'


module HpricotAttributes
    def set_attributes_from_hpricot(h)
        h.children.select { |c| c.class == Hpricot::Elem }.each do |c|
            self.instance_variable_set "@#{c.name}".to_sym, c.inner_text
        end
    end
end

module Pentabarf
    class Conference
        include HpricotAttributes
        attr_reader :title, :subtitle, :venue, :city, :start, :end, :days,
                    :release, :day_change, :timeslot_duration, :events
        def initialize(args)
            uri      = args[:uri]
            fallback = args[:fallback]
            h = 
            begin
                h = open(uri) { |f| Hpricot(f) }
            rescue
                STDERR.puts "warning: could not open #{uri}"
                open(fallback) { |f| Hpricot(f) }
            end

            # set attributes from the corresponding XML part
            conf = h.at('//schedule/conference')
            set_attributes_from_hpricot(conf)
            @events = []
            days = h.search('//schedule/day')
            days.each do |day|
                date   = day.attributes['date']
                events = day.search('event')
                events.each do |event|
                    @events.push(Event.new(:event => event, :date => date))
                end
            end
#            @events.each { |e| puts e.class }
#            @events.sort! # FIXME
#            puts @events.inspect
        end
    end
    
    class Event
        include Comparable
        include HpricotAttributes
        attr_reader :id, :date, :start, :duration, :room, :tag, :title,
                    :subtitle, :track, :type, :language, :abstract,
                    :description, :persons

        def initialize(args)
            event = args[:event]
            @id = event.attributes['id']
            date  = args[:date]
            set_attributes_from_hpricot(event)
            # persons need to be dealt with separately
            @persons = []
            event.search('persons/person').each do |p|
                @persons.push(Person.new(p.attributes['id'], p.inner_text))
            end
        end

        def <=>(other)
            # compare date first
            if (self.date <=> other.date) != 0 then
                return self.date <=> other.date
            end
            # then starting time
            if (self.start <=> other.start) != 0 then
                return self.start <=> other.start
            end
            # then room number
            self.room <=> other.room
        end
    end

    class Person
        attr_reader :id, :name

        def initialize(id, name)
            @id   = id
            @name = name
        end
    end
end

conf = Pentabarf::Conference.new(:uri => 'http://fwef8uwe9fw',
                                 :fallback => 'sample_schedule.xml')

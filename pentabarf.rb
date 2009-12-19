require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'time'
require 'digest/sha2'

module HpricotAttributes
    def set_attributes_from_hpricot(h)
        # sets attributes (instance variables) from a given Hpricot element
        # if the corresponding XML looks like this, for example:
        # <conference>
        #   <title>26th Chaos Communication Congress</title>
        #   <subtitle>Here be dragons</subtitle>
        #   <venue>bcc - Berliner Congress Center</venue>
        # </conference>
        # the method sets @title, @subtitle and @venue correspondingly
        if h.class != Hpricot::Elem then
            raise ArgumentError, 'parameter needs to be an Hpricot::Elem'
        end
        if ! h.respond_to? 'children' then
            raise ArgumentError, 'parameter needs to have children'
        end
        h.children.select { |c| c.class == Hpricot::Elem }.each do |c|
            self.instance_variable_set "@#{c.name}".to_sym, c.inner_text
        end
    end
end

module Pentabarf
    class Conference
        include HpricotAttributes
        attr_reader :title, :subtitle, :venue, :city, :start, :end, :days,
                    :release, :day_change, :timeslot_duration, :events, :rooms
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
                    @events.push(Event.new(:event => event,
                                           :date  => date,
                                           :day_change => @day_change))
                end
            end
            @events.sort!
            @rooms = @events.map { |e| e.room }.uniq.sort
        end

        def current_block(date = Time.now)
            result = []
            @rooms.each do |room|
                current = @events.select do |e|
                    (e.room == room) && (e.start <= date) && (e.end >= date)
                end
                if current.size > 1 then
                    raise RuntimeError,
                        "more than one event in room #{room} at #{date}!"
                end
                if current.size == 1 then
                    result.push current.first
                end
            end
            result
        end

        def upcoming_block(date = Time.now, max_date = date + 60*60*5)
            result = []
            @rooms.each do |room|
                current = @events.select do |e|
                    (e.room == room) &&
                    (e.start > date) &&
                    (e.start <= max_date)
                end
                if current.size >= 1 then
                    result.push current.first
                end
            end
            result
        end
        
        def upcoming_blocks(date = Time.now)
            blocks = []
            begin
                current = []
                @rooms.each do |room|
                    evts = @events.select do |e|
                        (e.room == room) && (e.start >= date)
                    end
                    if evts.size >= 1 then
                        current.push evts.first
                    end
                end
                # put all the events that start at the same (minimal)
                # time in the block, the rest in skipped
                min_current = min_time(current, date)
                block, skipped = current.partition do |c|
                    c.start == min_current
                end
                blocks.push block if block.size > 0
                # find the nearest start date for the next event
                min_current = min_time(skipped, min_current)
                # min_current is the correct next date, if
                # it is earlier than the end time of the
                # earliest ending talk in the block ...
                min_end_evt = block.sort { |x,y| x.end <=> y.end }.first
                if min_end_evt then
                    if min_current < min_end_evt.end then
                        date = min_current
                    else
                        date = min_end_evt.end
                    end
                else
                    date = min_current
                end
            end until block.size == 0 && skipped.size == 0
            blocks
        end

        private
        def min_time(event_collection, curr_date)
            case event_collection.size
            when 0 then
                curr_date + 1 # empty array, just advance by 1 second
            when 1 then
                event_collection.first.start
            else
                event_collection.sort { |x,y| x.start <=> y.start }.first.start
            end
        end
    end
    
    class Event
        include Comparable
        include HpricotAttributes
        attr_reader :id, :date, :start, :duration, :room, :tag, :title,
                    :subtitle, :track, :type, :language, :abstract,
                    :description, :persons, :end

        def initialize(args)
            event      = args[:event]
            @id        = event.attributes['id']
            @date      = args[:date]
            day_change = args[:day_change]

            set_attributes_from_hpricot(event)
            # persons need to be dealt with separately
            @persons = []
            event.search('persons/person').each do |p|
                @persons.push(Person.new(p.attributes['id'], p.inner_text))
            end
            # the day in Pentabarf does not stop at 23:59, but at the
            # "day_change" conference parameter. This means that events
            # at day x before day_change are actually at day x + 1.
            if @start < day_change then
                @date = (Date.parse(@date) + 1).strftime
            end
            # use Time objects for start and end
            @start = Time.parse "#{@date} #{@start}" 
            duration_hours, duration_minutes =
                @duration.split(':').map { |e| e.to_i }
            @end = @start + duration_minutes * 60 + duration_hours * 60 * 60
        end

        def <=>(other)
            # compare starting time
            if (self.start <=> other.start) != 0 then
                return self.start <=> other.start
            end
            # then room number
            self.room <=> other.room
        end

        def title_id_hash
            id_hash(@title)
        end

        def subtitle_id_hash
            id_hash(@subtitle)
        end

        private
        def id_hash(attribute)
            # add a hash over attribute to the id, as we might need to
            # regenerate the file if that information changes
            digest = Digest::SHA256.new().update(attribute).to_s[1..10]
            "#{@id}_#{digest}"
        end
    end

    class Person
        attr_reader :id, :name

        def initialize(id, name)
            @id   = id
            @name = name
        end

        def id_hash
            digest = Digest::SHA256.new().update(@name).to_s[1..10]
            "#{@id}_#{digest}"
        end
    end
end

#conf = Pentabarf::Conference.new(:uri => 'http://fwef8uwe9fw',
#                                 :fallback => 'sample_schedule.xml')
#
#puts conf.current_block.inspect
#puts conf.current_block(Time.parse("2009-12-27 10:00")).inspect
#puts conf.current_block(Time.parse("2009-12-27 20:30")).inspect
#
#puts conf.upcoming_block(Time.now).inspect
#conf.upcoming_block(Time.parse("2009-12-27 09:50")).each do |e|
#    puts e.title
#    puts e.subtitle
#    puts e.to_filename('gsm')
#end

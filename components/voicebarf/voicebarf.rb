# See http://docs.adhearsion.com for more information on how to write components or
# look at the examples in newly-created projects.

# components/my_component/my_component.rb

# define ActiveRecord classes
class ::Reminder < ActiveRecord::Base
end

class ::Call < ActiveRecord::Base
end

initialization do
    # initialize Pentabarf object
    COMPONENTS.voicebarf['pentabarf'] = Pentabarf::Conference.new(
        :uri      => COMPONENTS.voicebarf['pentabarf_xml_uri'],
        :fallback => COMPONENTS.voicebarf['pentabarf_xml_file']
    )

    # initialize ActiveRecord DB connection
    db_config = COMPONENTS.voicebarf['database']

    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::Base.logger = Logger.new(STDERR)
end

methods_for :dialplan do
    def play_conferencename
        calls = ::Call.count(:conditions => { :caller_id => callerid })

        # play event name (shortened if caller has called before)
        if calls > 1 then
            # if caller has called before, use the shortened event name
            play "voicebarf/conference/conferencename-shortened"
        else
            play "voicebarf/conference/conferencename"
        end
    end

    def play_event(event)
        #   talk.title, talk.subtitle by talk.speakers started at time
        #   in lecture hall x
        #   To rate the talk "in lecture hall 1", press 1 ...
        # For earlier talks, press 0
        #puts event.inspect
        #puts event.to_filename('wav')
        play_event_title event
        play_event_subtitle event
        play 'voicebarf/generic/by'
        play_event_persons event
        play 'voicebarf/generic/starting-at' # TODO record 'started at'
        play_event_time event
    end

    def play_event_title(event)
        play_with_fallback("voicebarf/event/title/#{event.title_id_hash}.wav",
                           'voicebarf/generic/unnamed-event')
    end

    def play_event_subtitle(event)
        play_with_fallback("voicebarf/event/subtitle/" +
                           "#{event.subtitle_id_hash}.wav",
                           '')
    end

    def play_event_persons(event)
        event.persons.each_with_index do |person, i|
            # John Doe, Jane Doe and Foo Bar
            if i < event.persons.size - 1 then
                sleep 0.5 # a short pause to indicate a comma
            elsif event.persons.size > 1
                # before the last one, say "and"
                play 'voicebarf/generic/and'
                sleep 0.3
            end
            play_with_fallback("voicebarf/speaker/#{person.id_hash}.wav",
                               'voicebarf/generic/unnamed-person')
        end
    end

    def play_with_fallback(file, fallback)
        file_without_extension = file.sub('.wav', '')
        ahn_log.voicebarf.debug "file without extension #{file_without_extension}"
        if File.exists?(File.join COMPONENTS.voicebarf['asterisk_sounds'], file)
            then
            play file_without_extension
        else
            # TODO record fallback files
            ahn_log.voicebarf.warn "falling back for file #{file} to #{fallback}"
            play fallback
        end
    end

    def play_event_time(event)
        hour    = event.start.strftime("%02H")
        minutes = event.start.strftime("%02M")
        am_pm   = hour.to_i >= 12 ? "pm" : "am"
        # special "named" points in time
        if hour == "00" && minutes == "00" then
            play "voicebarf/generic/time/midnight"
        elsif hour == "12" && minutes == "00" then
            play "voicebarf/generic/time/noon"
        elsif hour == "17" && minutes == "00" then
            play "voicebarf/generic/time/teatime"
        else
            # hour minute am/pm
            play "voicebarf/generic/time/hours/#{hour}"
            # TODO record 'something'
            play_with_fallback("voicebarf/generic/time/minutes/#{minutes}.wav",
                               'voicebarf/generic/time/minutes/something')
            play "voicebarf/generic/time/#{am_pm}"
        end 
    end

    def get_time
        time = Time.now

        # in debug mode, ask for date and time (format YYYYMMDDHHMM)
        if COMPONENTS.voicebarf['debug'] then
            play 'voicebarf/generic/debug/debug-mode'
            time_input = input(12, :timeout => 10.seconds,
                                   :play => [ 'voicebarf/generic/debug/please-enter-date-and-time' ])
            time = Time.parse(time_input)
        end
        time
    end
end

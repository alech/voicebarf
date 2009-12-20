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

    if COMPONENTS.voicebarf['reminders'] then
        COMPONENTS.voicebarf['reminderthread'] = Thread.new do
            # Wait for system to settle
            sleep 5
            while true do
                reminders = ::Reminder.find(:all, :conditions => \
                        ["done = ? AND time <= ?", false, Time.now.to_i])
                reminders.each do |reminder|
                    puts "Now calling #{reminder.phonenumber} (#{reminder})"
                    begin
                        # TODO: add retries here
                        VoIP::Asterisk.manager_interface.call_into_context(COMPONENTS.voicebarf['reminders_protocol'] + '/hctest',
                                'notification_incoming', {:variables => {:reminder_id => reminder.id}})
                    rescue Exception=>e
                        puts "Error: #{e}"
                        next
                    end

                    # Mark as done here, and let adhearsion/asterisk
                    # handle the 'try again' foobar.
                    reminder.done = true
                    reminder.save!
                end
                sleep 5
            end
        end
    end

    # update the Pentabarf::Conference object regularly, as its content
    # might change during the conference (regularly happens at Chaos
    # Communication Congress ;-)
    COMPONENTS.voicebarf['scheduleupdatethread'] = Thread.new do
        while true do
            sleep 60
            ahn_log.voicebarf.debug "Trying to update the schedule"
            begin
                COMPONENTS.voicebarf['pentabarf'] = Pentabarf::Conference.new(
                    :uri      => COMPONENTS.voicebarf['pentabarf_xml_uri']
                )
                ahn_log.voicebarf.debug "Successfully updated the schedule"
            rescue => ex
                ahn_log.voicebarf.error "Something went wrong during the update of the schedule: #{ex.class}: #{ex.message}"
            end
        end
    end
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

    def play_event(event, has_started = false)
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
        if has_started then
            play 'voicebarf/generic/started-at'
        else
            play 'voicebarf/generic/starting-at'
        end
        play_event_time event
        play_event_room event
        if ! has_started && COMPONENTS.voicebarf['reminders'] then
            play_input_reminder(event)
        end
    end

    def play_input_reminder(event)
        dtmf = COMPONENTS.voicebarf['dtmf_mapping'][event.room]
        ahn_log.voicebarf.debug "DTMF: #{dtmf}"
        if ! dtmf then
            ahn_log.voicebarf.warn "missing DTMF mapping for #{event.room}, using 1"
            dtmf = 1
        end
        remind_input = input(1, :timeout => 2.seconds,
                             :play => [ 'voicebarf/generic/to-be-reminded', 'voicebarf/generic/press', 'voicebarf/generic/numbers/' + '%02d' % dtmf ])
        if remind_input.to_i == dtmf then
            ahn_log.voicebarf.debug "Creating reminder for event #{event.inspect}"
            ::Reminder.create(:phonenumber => callerid, 
                              :event_id   => event.id,
                              :done       => false,
                              :time       => (event.start - 5*60).to_i)
            play 'voicebarf/generic/thank-you'
            play 'voicebarf/generic/reminder/we-will-call-you-to-remind-you-of'
            play_event_title event
            play 'voicebarf/generic/reminder/five-minutes-before-it-starts'
        end
    end

    def play_event_title(event)
        play_with_fallback("voicebarf/event/title/#{event.title_id_hash}.wav",
                           'voicebarf/generic/unknown-event')
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
                               'voicebarf/generic/unknown-person')
        end
    end

    def play_with_fallback(file, fallback)
        file_without_extension = file.sub('.wav', '')
        ahn_log.voicebarf.debug "file without extension #{file_without_extension}"
        if File.exists?(File.join COMPONENTS.voicebarf['asterisk_sounds'], file)
            then
            play file_without_extension
        else
            ahn_log.voicebarf.warn "falling back for file #{file} to #{fallback}"
            play fallback
        end
    end

    def play_event_time(event)
        hour    = event.start.strftime("%02H")
        minutes = event.start.strftime("%02M")
        am_pm   = hour.to_i >= 12 ? "pm" : "am"

        hour_corrected = hour.to_i > 12 ? '%02d' % (hour.to_i - 12) : hour
        # special "named" points in time
        if hour == "00" && minutes == "00" then
            play "voicebarf/generic/time/midnight"
        elsif hour == "12" && minutes == "00" then
            play "voicebarf/generic/time/noon"
        elsif hour == "17" && minutes == "00" then
            play "voicebarf/generic/time/teatime"
        else
            # hour minute am/pm
            play "voicebarf/generic/time/hours/#{hour_corrected}"
            play_with_fallback("voicebarf/generic/time/minutes/#{minutes}.wav",
                               'voicebarf/generic/time/minutes/something')
            play "voicebarf/generic/time/#{am_pm}"
        end 
    end

    def play_event_room(event)
        play "voicebarf/room/#{event.room}"
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

# vim:set tabstop=4 expandtab textwidth=1024 shiftwidth=4

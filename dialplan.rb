default {
    sleep 0.5
    # record caller in the database
    ::Call.create(:caller_id => callerid, 
                  :time => Time.now.strftime('%Y%m%d%H%M%S'))
    play_conferencename
    +talks_now
}

talks_now {
    play 'voicebarf/generic/talks-currently-running'
    time = get_time

    # Talks currently running
    # find matching talks and iterate over them
    COMPONENTS.voicebarf['pentabarf'].current_block(time).each do |event|
        play_event(event, true)
    end
    sleep 1
    +upcoming_talks
}

upcoming_talks {
    play 'voicebarf/generic/upcoming-talks'

    time = get_time
    # Upcoming talks
    # find matching talks and iterate over them
    #   talk.title, talk.subtitle by talk.speakers starting at time in lecture hall x
    #   Press 1/2/3 to be reminded 5 minutes before the talk.
    # find next matching block and iterate over the talks (until user hangs up or fahrplan is empty) ...
    COMPONENTS.voicebarf['pentabarf'].upcoming_blocks(time).each do |block|
        block.each do |event|
            play_event(event, false)
        end
        sleep 1
    end
}

# This context is entered when a user is called back from the system.
# This is ugly, really, but currently, there is no other way.
notification_incoming {
    # Get reminder
    reminder_id = get_variable('reminder_id')
    reminder = ::Reminder.find(reminder_id.to_i)

    event_id = reminder.event_id
    callee = reminder.phonenumber

    # Get event.
    events = COMPONENTS.voicebarf['pentabarf'].events
    event = events.find do |e| e.id == event_id end

    # Wait for phone to settle ;-)
    sleep 0.5

    # Play the actual announcement
    play 'voicebarf/generic/reminder/hello-the-talk'
    play_event_title event
    play 'voicebarf/generic/reminder/starts-in-five-minutes'
    play_event_room event
}

# vim:set tabstop=4 expandtab textwidth=1024 shiftwidth=4

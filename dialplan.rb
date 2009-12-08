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
    dtmf = 1
    COMPONENTS.voicebarf['pentabarf'].current_block(time).each do |event|
        play_event(event, true, dtmf)
        dtmf = dtmf +1
    end
    sleep 1
    +upcoming_talks
}

upcoming_talks {
    play 'voicebarf/generic/upcoming-talks'
    time = Time.parse("200912281500")

    # Upcoming talks
    # find matching talks and iterate over them
    #   talk.title, talk.subtitle by talk.speakers starting at time in lecture hall x
    #   Press 1/2/3 to be reminded 5 minutes before the talk.
    # find next matching block and iterate over the talks (until user hangs up or fahrplan is empty) ...
    dtmf = 1
    COMPONENTS.voicebarf['pentabarf'].upcoming_block(time).each do |event|
        play_event(event, false, dtmf)
        dtmf = dtmf + 1 
    end
}

# This context is entered when a user is called back from the system.
# This is ugly, really, but currently, there is no other way.
notification_incoming {
    event_id = get_variable('event_id')
    callee = get_variable('callee')

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

    # Mark call as done
    reminder = ::Reminder.find(:first, :conditions => [ "phonenumber = ? AND event_id = ?", callee, event_id ])
    reminder.done = true
    reminder.save!
}

rate {
    # maybe no context, but a method?
    # should receive @id set to the talk's ID
    # 
    # The rating is divided in the following categories:
    # iterate over categories (TODO: defined where, they are probably not in
    # the Pentabarf XML?)
    # Please rate from 1 to 5 where 5 is best and 1 is worst.
    # iterate over categories:
    #   Please enter your rating for the category "..."
    # Thank you.
    # You now have the chance to record an audio comment after the tone. Alternatively, you can just hang up now.
    # save audio file (TODO: discuss with pentabarf team/Sven if it can be uploaded to pentabarf directly)
    # rate talk on Barf (add a comment that this is a voicebarf rating and add the timestamp)
}

remind {
    # maybe no context, but a method?
    # should receive @id set to the talk's ID
    # 
    # TODO record "We will call you to remind you of talk.title at time."
    # TODO record "The talk talk.title starts in 5 minutes in talk.room"
    # Save reminder in database
    # have a different script that calls people to remind them of the talk
}

# vim:set tabstop=4 expandtab textwidth=1024 shiftwidth=4

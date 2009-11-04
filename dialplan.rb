adhearsion {
    sleep 0.5
    ::Call.create(:caller_id => callerid, 
                  :time => Time.now.strftime('%Y%m%d%H%M%S'))
    +talks_now
}

talks_now {
    calls = ::Call.count(:conditions => { :caller_id => callerid })
    puts @@pentabarf.title
    if calls > 1 then
        # if caller has called before, use the shortened event name
        play "voicebarf/event/eventname-shortened"
    else
        play "voicebarf/event/eventname"
    end
    # play event name (shortened if caller has called before)
    # Talks currently running
    # find matching talks and iterate over them
    # TODO record "started at" 
    #   talk.title, talk.subtitle by talk.speakers started at time in lecture hall x
    #   To rate the talk "in lecture hall 1", press 1 ...
    # For earlier talks, press 0
    +upcoming_talks
}

upcoming_talks {
    # play event name (shortened if caller has called before)
    # Upcoming talks
    # find matching talks and iterate over them
    #   talk.title, talk.subtitle by talk.speakers starting at time in lecture hall x
    #   Press 1/2/3 to be reminded 5 minutes before the talk.
    # find next matching block and iterate over the talks (until user hangs up or fahrplan is empty) ...
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

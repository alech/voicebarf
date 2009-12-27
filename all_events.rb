require 'pentabarf'
conf = Pentabarf::Conference.new(:uri => 'http://events.ccc.de/congress/2009/Fahrplan/schedule.en.xml',
                                 :fallback => '68.xml')
speakers = {}
conf.events.each do |e|
    e.persons.each do |p|
        speakers[p.name] = [ p, e.title ]
    end
end

speakers.each do |name, p|
    puts "mv #{p[0].id}.wav ../speaker/#{p[0].id_hash}.wav"
end

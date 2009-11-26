require 'pentabarf'
conf = Pentabarf::Conference.new(:uri => 'http://fwef8uwe9fw',
                                 :fallback => '68.xml')
conf.events.each do |e|
    #puts "#{e.title} | #{e.subtitle}"
    puts "git mv #{e.id}_t.wav ../../../event/title/#{e.title_id_hash}.wav"
    puts "git mv #{e.id}_s.wav ../../../event/subtitle/#{e.subtitle_id_hash}.wav"
end

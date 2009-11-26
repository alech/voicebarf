require 'pentabarf'
conf = Pentabarf::Conference.new(:uri => 'http://fwef8uwe9fw',
                                 :fallback => '68.xml')
conf.events.each do |e|
#    puts e.title + " - " + e.subtitle
    e.persons.each do |p|
 #        puts "\e[1;31m#{p.name}\e[0m"
         puts "#{p.name}\n#{p.id}"
         #puts p.id_hash + '.wav'
    end
end

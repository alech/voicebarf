require 'pentabarf'
conf = Pentabarf::Conference.new(:uri => 'http://fwef8uwe9fw',
                                 :fallback => '68.xml')
person_map = {}
conf.events.each do |e|
#    puts e.title + " - " + e.subtitle
    e.persons.each do |p|
 #        puts "\e[1;31m#{p.name}\e[0m"
#         puts "#{p.name}\n#{p.id}"
         #puts p.id_hash + '.wav'
         person_map[p.name] = p.id
    end
end
person_map.sort.each { |k,v| puts k; puts v }

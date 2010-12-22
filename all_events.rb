require 'pentabarf'
conf = Pentabarf::Conference.new(:uri => 'schedule-184773.xml')
speakers = {}
conf.events.each do |e|
	puts e.start
	puts "#{e.title} - #{e.title_id_hash}"
	puts "#{e.subtitle} - #{e.subtitle_id_hash}" if e.subtitle != ""
    e.persons.each do |p|
		puts "#{p.name} - #{p.id_hash}"
    end
	puts
end


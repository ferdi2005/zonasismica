require 'mediawiki_api'
require 'roo'
require 'httparty'
require 'json'

unless File.exist? "#{__dir__}/.config"
    puts 'Inserisci username:'
    print '> '
    username = gets.chomp
    puts 'Inserisci password:'
    print '> '
    password = gets.chomp
    puts "Attivo? Scrivere y o n. Nel caso in cui la stringa sia differente, verrà interpretata come n"
    print '> '
    File.open("#{__dir__}/.config", "w") do |file| 
      file.puts username
      file.puts password
      file.puts active
    end
end
userdata = File.open("#{__dir__}/.config", "r").to_a

wikipedia = MediawikiApi::Client.new("https://it.wikipedia.org/w/api.php")
wikidata = MediawikiApi::Client.new("https://www.wikidata.org/w/api.php")
wikidata.log_in(userdata[0].strip, userdata[1].strip)
active = userdata[2].strip == "y" ? true : false
xlsx = Roo::Spreadsheet.open("classificazione2020.xlsx")
xlsx.default_sheet = xlsx.sheets[0]
c = 0
tot = 0
n = 0
wikidata_array = []
different_array = []
unless File.exist? "#{__dir__}/lista.txt"
    url = "https://petscan.wmflabs.org/?format=json&doit=&categories=Comuni%20d%27Italia&depth=8&project=wikipedia&lang=it&templates_yes=divisione%20amministrativa"
    petscan = HTTParty.get(url, timeout: 1000).to_h["*"][0]["a"]["*"]
    lista = File.open("#{__dir__}/lista.txt", "w")
    lista.write(petscan.to_json)
    lista.close
end
petscan = JSON.parse(File.read("#{__dir__}/lista.txt"))
puts 'Inizio a processare le pagine...'
begin
    xlsx.each_row_streaming do |row|
        if !row[0].empty? && row[0].value != "Regione"
            tot += 1
            # stringaricerca = 'intitle:"' + row[3].value.strip + '" comune italiano'
            # search = wikipedia.query(list: "search", srsearch: stringaricerca, srlimit: 1)
            if petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_"))} != nil || petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_").gsub("-", "_"))} != nil ||  petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_").gsub("_", "-"))} != nil || petscan.find { |e| e["title"].include?(row[3].value.strip.gsub("è","é").gsub(" ", "_"))} != nil || petscan.find { |e| e["title"].include?(row[3].value.strip.gsub("é","è").gsub(" ", "_"))} != nil 
                # title = search.data["search"][0]["title"]
                if petscan.select { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_"))}.count > 1
                    if petscan.find { |e| e["title"] == row[3].value.strip.gsub(" ", "_")} != nil
                        title = petscan.find { |e| e["title"] == row[3].value.strip.gsub(" ", "_")}["title"]
                    elsif petscan.find { |e| e["title"] == "#{row[3].value.strip} (Italia)".gsub(" ", "_")} != nil
                        title = petscan.find { |e| e["title"] == "#{row[3].value.strip} (Italia)".gsub(" ", "_")}["title"]
                    else
                        puts "#{row[3].value.strip} più opzioni"
                        n += 1
                        next
                    end
                elsif petscan.find { |e| e["title"] == "#{row[3].value.strip} (Italia)".gsub(" ", "_")} != nil
                    title = petscan.find { |e| e["title"] == "#{row[3].value.strip} (Italia)".gsub(" ", "_")}["title"]
                elsif petscan.find { |e| e["title"].include?(row[3].value.strip.gsub("è","é").gsub(" ", "_"))} != nil 
                    title = petscan.find { |e| e["title"].include?(row[3].value.strip.gsub("è","é").gsub(" ", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[3].value.strip.gsub("é","è").gsub(" ", "_"))} != nil 
                    title = petscan.find { |e| e["title"].include?(row[3].value.strip.gsub("é","è").gsub(" ", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_"))} != nil
                    title = petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_").gsub("-", "_"))} != nil
                    title = petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_").gsub("-", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_").gsub("_", "-"))} != nil
                    title = petscan.find { |e| e["title"].include?(row[3].value.strip.gsub(" ", "_").gsub("_", "-"))}["title"]
                end
                begin
                    wikidata = wikipedia.query prop: :iwlinks, titles: title, iwprefix: :d
                    item = wikidata.data["pages"].first[1]["iwlinks"][0]["*"]
                    zonasismica = row[4].value
                    zonesismiche = []
                    zonasismica.to_s.scan(/(\d[ABS]*)\-*/i).each { |z| zonesismiche.push(z[0])}

                    check = HTTParty.get("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{item}&format=json&languages=en")
                    
                    is_there = check.to_hash["entities"][item]["claims"]["P9235"]

                    if is_there.nil?
                        wikidata_array.push([item, zonesismiche.join("-")])
                    else
                        stated_id = check.to_hash["entities"][item]["claims"]["P9235"][0]["mainsnak"]["datavalue"]["value"]["id"]
                        matching_zones = {
                            "1": "Q106435253",
                            "1-2A": "Q106435254",
                            "2": "Q106435255",
                            "2A": "Q106435256",
                            "2A-2B": "Q106435257",
                            "2B": "Q106435258",
                            "2A-3A-3B": "Q106435259",
                            "2B-3A": "Q106435260",
                            "3": "Q106435261",
                            "3S": "Q106435262",
                            "3A": "Q106435263",
                            "3A-3B": "Q106435264",
                            "3B": "Q106435265",
                            "3-4": "Q106435266",
                            "4": "Q106435267"
                        }
                        
                        if stated_id != matching_zones[zonesismiche.join("-").to_sym]
                            different_array.push([item, zonesismiche.join("-")])
                            c += 1
                        end
                    end
                rescue
                    puts "#{title} nessun elemento"
                    next
                end
            else 
                puts "#{row[3].value.strip} non trovato"
                n += 1
            end
        end
    end
rescue Interrupt => e 
    puts "Salvo..."
    lista = File.open("#{__dir__}/wikidata.txt", "w")
    lista.write(wikidata_array.to_json)
    lista.close

    differenti = File.open("#{__dir__}/differenti.txt", "w")
    differenti.write(different_array.to_json)
    differenti.close
    puts "Elaborati #{tot} comuni di cui #{c} con discrepanze. Ci sono #{n} errori."
end
lista = File.open("#{__dir__}/wikidata.txt", "w")
lista.write(wikidata_array.to_json)
lista.close

differenti = File.open("#{__dir__}/differenti.txt", "w")
differenti.write(different_array.to_json)
differenti.close

puts "Elaborati #{tot} comuni di cui #{c} con discrepanze Ci sono #{n} errori.."
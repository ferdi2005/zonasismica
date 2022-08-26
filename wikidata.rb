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
zone = CSV.read("classificazione2022.csv", headers: true, col_sep: ";", skip_blanks: true)
c = 0
tot = 0
n = 0
wikidata_array = []
different_array = []
unless File.exist? "#{__dir__}/lista.txt"
    url = "https://petscan.wmflabs.org/?format=json&doit=&categories=Comuni%20d%27Italia&depth=8&project=wikipedia&lang=it&templates_yes=divisione%20amministrativa&negcats=Frazioni%20comunali%20d%27Italia"
    petscan = HTTParty.get(url, timeout: 1000).to_h["*"][0]["a"]["*"]
    lista = File.open("#{__dir__}/lista.txt", "w")
    lista.write(petscan.to_json)
    lista.close
end
petscan = JSON.parse(File.read("#{__dir__}/lista.txt"))
puts 'Inizio a processare le pagine...'
begin
    zone.each do |row|
        next if row[0].nil? || row[0]&.empty?
        row = row.map { |_,i| i&.strip } # Rimuovo spazi bianchi non necessari
            tot += 1
                    # Sostituzione regioni con nomi non standard
        case row[0]
        when "Friuli- Venezia Giulia"
            row[0] = "Friuli-Venezia Giulia"
        end

        # Sostituzione province con nomi non standard
        case row[1]
        when "Bolzano - Bozen"
            row[1] = "Bolzano"
        when "Valle d'Aosta"
            row[1] = "Aosta"
        when "Reggio di Calabria"
            row[1] = "Reggio Calabria"
        end

        # Sostituzione comuni con nomi non standard
        case row[3]
        when "Reggio di Calabria"
            row[3] = "Reggio Calabria"
        when "Reggio nell'Emilia"
            row[3] = "Reggio Emilia"
        when "Ceresole Alba"
            row[3] = "Ceresole d'Alba"
        when "Portovenere"
            row[3] = "Porto Venere"
        when "San Dorligo della Valle-Dolina"
            row[3] = "San Dorligo della Valle"
        when "Capaccio"
            row[3] = "Capaccio Paestum"
        when "San Mauro la Bruca"
            row[3] = "San Mauro La Bruca"
        when "Moio Alcantara"
            row[3] = "Mojo Alcantara"
        when "Emarèse"
            row[3] = "Émarèse"
        when "Etroubles"
            row[3] = "Étroubles"
        when "Cerrina Monferrato"
            row[3] = "Cerrina"
        when "Ulà Tirso"
            row[3] = "Ula Tirso"
        when "Alcara li Fusi"
            row[3] = "Alcara Li Fusi"
        when "Vodo Cadore"
            row[3] = "Vodo di Cadore"
        when "San Valentino in AbruzzoCiteriore"
            row[3] = "San Valentino in Abruzzo Citeriore"
        end

        row[3].gsub!("sulla strada del vino", "sulla Strada del Vino") if row[3].include? "sulla strada del vino"

        if petscan.select { |e| e["title"].include?(row[3].gsub(" ", "_"))}.count == 1
            item = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_"))}["q"]
        elsif petscan.select { |e| e["title"].include?(row[3].gsub(" ", "_"))}.count > 1
            if petscan.find { |e| e["title"] == row[3].gsub(" ", "_")} != nil
                item = petscan.find { |e| e["title"] == row[3].gsub(" ", "_")}["q"]
            elsif petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")} != nil
                item = petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")}["q"]
            elsif petscan.find { |e| e["title"] == "#{row[3]} (comune)".gsub(" ", "_")} != nil
                item = petscan.find { |e| e["title"] == "#{row[3]} (comune)".gsub(" ", "_")}["q"]
            elsif petscan.find { |e| e["title"] == "#{row[3]} (comune italiano)".gsub(" ", "_")} != nil
                item = petscan.find { |e| e["title"] == "#{row[3]} (comune italiano)".gsub(" ", "_")}["q"]
            # verifica la regione come disambiguante
            elsif petscan.find { |e| e["title"] == "#{row[3]} (#{row[0]})".gsub(" ", "_")} != nil
                item = petscan.find { |e| e["title"] == "#{row[3]} (#{row[0]})".gsub(" ", "_")}["q"]
            # verifica la provincia come disambiguante
            elsif petscan.find { |e| e["title"] == "#{row[3]} (#{row[1]})".gsub(" ", "_")} != nil
                item = petscan.find { |e| e["title"] == "#{row[3]} (#{row[1]})".gsub(" ", "_")}["q"]
            else
                puts "#{row[3]} più opzioni"
                n += 1
                next
            end
        elsif petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")} != nil
            item = petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("è","é").gsub(" ", "_"))} != nil 
            item = petscan.find { |e| e["title"].include?(row[3].gsub("è","é").gsub(" ", "_"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("é","è").gsub(" ", "_"))} != nil 
            item = petscan.find { |e| e["title"].include?(row[3].gsub("é","è").gsub(" ", "_"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_"))} != nil
            item = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("-", "_"))} != nil
            item = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("-", "_"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("_", "-"))} != nil
            item = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("_", "-"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" - ", "-").gsub(" ", "_"))} != nil
            item = petscan.find { |e| e["title"].include?(row[3].gsub(" - ", "-").gsub(" ", "_"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("-", " - ").gsub(" ", "_"))} != nil
            item = petscan.find { |e| e["title"].include?(row[3].gsub("-", " - ").gsub(" ", "_"))}["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("d'","di ").gsub(" ", "_"))} != nil 
            item = petscan.find { |e| e["title"].include?(row[3].gsub("d'","di ").gsub(" ", "_"))}["q"]
        else
            puts "#{row[3]} non trovato"
            n += 1
            next
        end
            
        begin
            # wikidata = wikipedia.query prop: :iwlinks, titles: title, iwprefix: :d
            # item = wikidata.data["pages"].first[1]["iwlinks"][0]["*"]
            zonasismica = row[4]
            zonesismiche = []
            zonasismica.to_s.scan(/(\d[ABs]*)\-*/i).each { |z| zonesismiche.push(z[0])}

            check = HTTParty.get("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{item}&format=json&languages=en")
            
            is_there = check.to_hash["entities"][item]["claims"]["P9235"]

            if is_there.nil?
                wikidata_array.push([item, zonesismiche.join("-").upcase])
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
                    different_array.push([item, zonesismiche.join("-").upcase])
                    c += 1
                end
            end
        rescue
            puts "#{title} nessun elemento"
            next
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
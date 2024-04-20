require 'mediawiki_api'
require 'roo'
require 'httparty'
require 'json'
require 'csv'
require 'progress_bar'

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
# wikidata = MediawikiApi::Client.new("https://www.wikidata.org/w/api.php")

wikipedia.log_in(userdata[0].strip, userdata[1].strip)
active = userdata[2].strip == "y" ? true : false
wikidata_mode = userdata[3].strip == "y" ? true : false

f = File.open("comuni.csv", "w")
m = File.open("mancanti.csv", "w")
# zone = Roo::Spreadsheet.open("classificazione2020.zone")
# zone.default_sheet = zone.sheets[0]
zone = CSV.read("classificazione2023.csv", headers: true, col_sep: ";", skip_blanks: true)
c = 0
tot = 0
n = 0
unless File.exist? "#{__dir__}/lista.txt"
    url = "https://petscan.wmflabs.org/?format=json&doit=&categories=Comuni%20d%27Italia&depth=8&project=wikipedia&lang=it&templates_yes=divisione%20amministrativa&negcats=Frazioni%20comunali%20d%27Italia&show_redirects=no"
    petscan = HTTParty.get(url, timeout: 1000).to_h["*"][0]["a"]["*"]
    lista = File.open("#{__dir__}/lista.txt", "w")
    lista.write(petscan.to_json)
    lista.close
end

if wikidata_mode
    wikidata_array = []
    different_array = []
end

petscan = JSON.parse(File.read("#{__dir__}/lista.txt"))
puts 'Inizio a processare le pagine...'

# row[0]: REGIONE
# row[1]: PROVINCIA
# row[2]: SIGLA PROVINCIA
# row[3]: COMUNE
# row[4]: CODICE ISTAT
# row[5]: ZONA SISMICA
begin
    # zone.each_row_streaming do |row|
    bar = ProgressBar.new(zone.count)
    zone.each do |row|
        next if row[0].nil? || row[0]&.empty?
        row = row.map { |_,i| i&.strip } # Rimuovo spazi bianchi non necessari

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
        row[3] = row[3].split("/")[0] # Rimuovo la denominazione in tedesco

        tot += 1
        # stringaricerca = 'intitle:"' + row[3] + '" comune italiano'
        # search = wikipedia.query(list: "search", srsearch: stringaricerca, srlimit: 1)
            # title = search.data["search"][0]["title"]
        if petscan.select { |e| e["title"].include?(row[3].gsub(" ", "_"))}.count == 1
            page = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.select { |e| e["title"].include?(row[3].gsub(" ", "_"))}.count > 1
            if petscan.find { |e| e["title"] == row[3].gsub(" ", "_")} != nil
                page = petscan.find { |e| e["title"] == row[3].gsub(" ", "_")}
                title = page["title"]
                item = page["q"]
            elsif petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")} != nil
                page = petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")}
                title = page["title"]
                item = page["q"]
            elsif petscan.find { |e| e["title"] == "#{row[3]} (comune)".gsub(" ", "_")} != nil
                page = petscan.find { |e| e["title"] == "#{row[3]} (comune)".gsub(" ", "_")}
                title = page["title"]
                item = page["q"]
            elsif petscan.find { |e| e["title"] == "#{row[3]} (comune italiano)".gsub(" ", "_")} != nil
                page = petscan.find { |e| e["title"] == "#{row[3]} (comune italiano)".gsub(" ", "_")}
                title = page["title"]
                item = page["q"]
            # verifica la regione come disambiguante
            elsif petscan.find { |e| e["title"] == "#{row[3]} (#{row[0]})".gsub(" ", "_")} != nil
                page = petscan.find { |e| e["title"] == "#{row[3]} (#{row[0]})".gsub(" ", "_")}
                title = page["title"]
                item = page["q"]
            # verifica la provincia come disambiguante
            elsif petscan.find { |e| e["title"] == "#{row[3]} (#{row[1]})".gsub(" ", "_")} != nil
                page = petscan.find { |e| e["title"] == "#{row[3]} (#{row[1]})".gsub(" ", "_")}
                title = page["title"]
                item = page["q"]
            else
                puts "#{row[3]} più opzioni"
                n += 1
                next
            end
        elsif petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")} != nil
            page = petscan.find { |e| e["title"] == "#{row[3]} (Italia)".gsub(" ", "_")}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("è","é").gsub(" ", "_"))} != nil 
            page = petscan.find { |e| e["title"].include?(row[3].gsub("è","é").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("é","è").gsub(" ", "_"))} != nil 
            page = petscan.find { |e| e["title"].include?(row[3].gsub("é","è").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_"))} != nil
            page = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("-", "_"))} != nil
            page = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("-", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("_", "-"))} != nil
            page = petscan.find { |e| e["title"].include?(row[3].gsub(" ", "_").gsub("_", "-"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub(" - ", "-").gsub(" ", "_"))} != nil
            page = petscan.find { |e| e["title"].include?(row[3].gsub(" - ", "-").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("-", " - ").gsub(" ", "_"))} != nil
            page = petscan.find { |e| e["title"].include?(row[3].gsub("-", " - ").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].include?(row[3].gsub("d'","di ").gsub(" ", "_"))} != nil 
            page = petscan.find { |e| e["title"].include?(row[3].gsub("d'","di ").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        else
            puts "#{row[3]} non trovato"
            n += 1
            next
        end 
        wikitext = wikipedia.query prop: :revisions, titles: title, rvprop: :content, rvslots: "*"
        begin

            # Verifica del dato su Wikipedia
            text = wikitext.data["pages"].first[1]["revisions"][0]["slots"]["main"]["*"]
            if text.match?(/\|\s*Zona\ssismica\s*=\s*([\d\w\-]+)/i)
                    zonasismica = row[5]
                    zonesismiche = []
                    zonasismica.to_s.scan(/(\d[ABs]*)\-*/i).each { |z| zonesismiche.push(z[0])}
                    matches = []
                    match = text.match(/\|\s*Zona\ssismica\s*=\s*([\dABs\-]+)/i)
                    match[1].to_s.scan(/(\d\w*)\-*/).each { |z| matches.push(z[0])}
                if matches.join("-") != zonesismiche.join("-").upcase
                    c += 1
                    f.write("#{title},#{matches.join("-")},#{zonesismiche.join("-").upcase}\n")
                    if active
                        text.gsub!(/\|\s*Zona\ssismica\s*=\s*[\w\d\-]+/i, "|Zona sismica = #{zonesismiche.join("-").upcase}")
                        wikipedia.edit(title: title, text: text, summary: "Aggiornamento del dato della zona sismica al 30 aprile 2023", bot: true)
                        puts "Pagina #{title} aggiornata con successo"
                    end
                end
            else
                puts "#{row[3]} trovato #{title} e non matchabile (#{row[5]})"
                m.write("#{title},#{row[5]}\n")
                n += 1
            end
            
            # Verifica del dato su Wikidata
            if wikidata_mode
                check = HTTParty.get("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{item}&format=json&languages=en")
                
                is_there = check.to_hash["entities"][item]["claims"]["P9235"]

                if is_there.nil?
                    wikidata_array.push([item, row[5].upcase])
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
                    
                    if stated_id != matching_zones[row[5].upcase.to_sym]
                        different_array.push([item, row[5].upcase])
                        c += 1
                    end
                end
            end

        rescue => e
            puts "#{row[3]}: #{e}"
            n += 1
            next
            
        end
        bar.increment!
    end
rescue Interrupt
    puts "Salvo..."
    f.close
    m.close

    # Salva i dati di Wikidata
    if wikidata_mode
        lista = File.open("#{__dir__}/wikidata.txt", "w")
        lista.write(wikidata_array.to_json)
        lista.close

        differenti = File.open("#{__dir__}/differenti.txt", "w")
        differenti.write(different_array.to_json)
        differenti.close
    end

    puts "Elaborati #{tot} comuni di cui #{c} con discrepanze. Ci sono #{n} errori."
end
f.close
m.close

# Salva i dati di Wikidata
if wikidata_mode
    lista = File.open("#{__dir__}/wikidata.txt", "w")
    lista.write(wikidata_array.to_json)
    lista.close

    differenti = File.open("#{__dir__}/differenti.txt", "w")
    differenti.write(different_array.to_json)
    differenti.close
end

puts "Elaborati #{tot} comuni di cui #{c} con discrepanze Ci sono #{n} errori.."
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
wikipedia.log_in(userdata[0].strip, userdata[1].strip)
active = userdata[2].strip == "y" ? true : false
f = File.open("frazioni.csv", "w")
m = File.open("mancanti_frazioni.csv", "w")
# zone = Roo::Spreadsheet.open("classificazione2020.zone")
# zone.default_sheet = zone.sheets[0]
zone = CSV.read("classificazione2022.csv", headers: true, col_sep: ";", skip_blanks: true)
c = 0
tot = 0
n = 0

request = wikipedia.query(list: :search, srsearch: 'insource:"Stato = ITA" insource:"Grado amministrativo = 4"', srnamespace: 0, srlimit: :max, srwhat: :text)

pages = request.data["search"]

# Procede con la continuazione
while !request["continue"].nil?
    request = wikipedia.query(list: :search, srsearch: 'insource:"Stato = ITA" insource:"Grado amministrativo = 4"', srnamespace: 0, srlimit: :max, srwhat: :text, sroffset: request["continue"]["sroffset"])
    pages += request.data["search"]
end

puts 'Inizio a processare le pagine...'
begin
    bar = ProgressBar.new(pages.count)
    unless File.exist? "#{__dir__}/frazioni.txt"
        pages.map! do |p|
            begin
                p["text"] = wikipedia.query(prop: :revisions, titles: p["title"], rvprop: :content, rvslots: "*").data["pages"].first[1]["revisions"][0]["slots"]["main"]["*"]

                p["comune"] = p["text"]&.match(/^\s*\|\s*Divisione\samm\sgrado\s3\s*=\s*(.+)$/i)[1].to_s
            rescue NoMethodError => e
                puts "Non trovato match #{p["title"]}"
                next
            end

            (puts "Non trovato match #{p["title"]}"; next) if p["comune"].empty?

            bar.increment!
            p
        end
        lista = File.open("#{__dir__}/frazioni.txt", "w")
        lista.write(pages.to_json)
        lista.close    
    end
    pages = JSON.parse(File.read("#{__dir__}/frazioni.txt"))
    pages.reject! { |p| p.nil? || (p["comune"].nil? || p["comune"].empty?) if p.nil? }

    bar = ProgressBar.new(zone.count)
    # zone.each_row_streaming do |row|
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

        tot += 1
        # stringaricerca = 'intitle:"' + row[3] + '" comune italiano'
        # search = wikipedia.query(list: "search", srsearch: stringaricerca, srlimit: 1)
            # page = search.data["search"][0]["title"]

    if pages.select { |e| e["comune"].include?(row[3])} != nil
        if pages.find { |e| e["comune"] == row[3]} != nil
            frazioni = pages.select { |e| e["comune"] == row[3]}
        elsif pages.find { |e| e["comune"] == "#{row[3]} (Italia)"} != nil
            frazioni = pages.select { |e| e["comune"] == "#{row[3]} (Italia)"}
        elsif pages.find { |e| e["comune"] == "#{row[3]} (comune)"} != nil
            frazioni = pages.select { |e| e["comune"] == "#{row[3]} (comune)"}
        elsif pages.find { |e| e["comune"] == "#{row[3]} (comune italiano)"} != nil
            frazioni = pages.select { |e| e["comune"] == "#{row[3]} (comune italiano)"}
        # verifica la regione come disambiguante
        elsif pages.find { |e| e["comune"] == "#{row[3]} (#{row[0]})"} != nil
            frazioni = pages.select { |e| e["comune"] == "#{row[3]} (#{row[0]})"}
        # verifica la provincia come disambiguante
        elsif pages.find { |e| e["comune"] == "#{row[3]} (#{row[1]})"} != nil
            frazioni = pages.select { |e| e["comune"] == "#{row[3]} (#{row[1]})"}
        end
    elsif pages.find { |e| e["comune"] == "#{row[3]} (Italia)"} != nil
        frazioni = pages.select { |e| e["comune"] == "#{row[3]} (Italia)"}
    elsif pages.find { |e| e["comune"].include?(row[3].gsub("è","é"))} != nil 
        frazioni = pages.select { |e| e["comune"].include?(row[3].gsub("è","é"))}
    elsif pages.find { |e| e["comune"].include?(row[3].gsub("é","è"))} != nil 
        frazioni = pages.select { |e| e["comune"].include?(row[3].gsub("é","è"))}
    elsif pages.find { |e| e["comune"].include?(row[3])} != nil
        frazioni = pages.select { |e| e["comune"].include?(row[3])}
    elsif pages.find { |e| e["comune"].include?(row[3].gsub("-", "_"))} != nil
        frazioni = pages.select { |e| e["comune"].include?(row[3].gsub("-", "_"))}
    elsif pages.find { |e| e["comune"].include?(row[3].gsub("_", "-"))} != nil
        frazioni = pages.select { |e| e["comune"].include?(row[3].gsub("_", "-"))}
    elsif pages.find { |e| e["comune"].include?(row[3].gsub(" - ", "-"))} != nil
        frazioni = pages.select { |e| e["comune"].include?(row[3].gsub(" - ", "-"))}
    elsif pages.find { |e| e["comune"].include?(row[3])} != nil
        frazioni = pages.select { |e| e["comune"].include?(row[3])}
    elsif pages.find { |e| e["comune"].include?(row[3].gsub("d'","di "))} != nil 
        frazioni = pages.select { |e| e["comune"].include?(row[3].gsub("d'","di "))}
    else
        frazioni = pages.select { |e| e["comune"].include?(row[3])}
    end 
    
    next if frazioni.nil? # Va avanti se il comune non ha frazioni
        frazioni.each do |page|
            next if page["comune"] == "Treppo Ligosullo" # eccezione
            begin
                title = page["title"] 
                text = page["text"]
                if text.match?(/\|\s*Zona\ssismica\s*=\s*([\d\w\-]+)/i)
                        zonasismica = row[4]
                        zonesismiche = []
                        zonasismica.to_s.scan(/(\d[ABs]*)\-*/i).each { |z| zonesismiche.push(z[0])}
                        matches = []
                        match = text.match(/\|\s*Zona\ssismica\s*=\s*([\dABs\-]+)/i)
                        match[1].to_s.scan(/(\d\w*)\-*/).each { |z| matches.push(z[0])}
                    if matches.join("-") != zonesismiche.join("-").upcase
                        c += 1
                        f.write("#{title},#{page["comune"]},#{matches.join("-")},#{zonesismiche.join("-").upcase}\n")
                        if active
                            text.gsub!(/\|\s*Zona\ssismica\s*=\s*[\w\d\-]+/i, "|Zona sismica = #{zonesismiche.join("-").upcase}")
                            wikipedia.edit(title: title, text: text, summary: "Aggiornamento del dato della zona sismica al 31 dicembre 2022 sulla base del comune", bot: true)
                            puts "Pagina #{title} aggiornata con successo"
                        end
                    end
                else
                   # puts "#{row[3]} trovato #{title} e non matchabile (#{row[4]})"
                    m.write("#{title},#{page["comune"]},#{row[4]}\n")
                    n += 1
                end
            rescue => e
                puts "#{row[3]}: #{e}"
                n += 1
                next
            end
        end
        bar.increment!
    end
rescue Interrupt
    puts "Salvo..."
    f.close
    m.close
    puts "Elaborati #{tot} frazioni di cui #{c} con discrepanze. Ci sono #{n} errori."
end
f.close
m.close
puts "Elaborati #{tot} frazioni di cui #{c} con discrepanze Ci sono #{n} errori.."
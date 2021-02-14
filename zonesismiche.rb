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
wikipedia.log_in(userdata[0].strip, userdata[1].strip)
active = userdata[2].strip == "y" ? true : false
f = File.open("comuni.csv", "w")
m = File.open("mancanti.csv", "w")
xlsx = Roo::Spreadsheet.open("classificazione2020.xlsx")
xlsx.default_sheet = xlsx.sheets[0]
c = 0
tot = 0
n = 0
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
                wikitext = wikipedia.query prop: :revisions, titles: title, rvprop: :content, rvslots: "*"
                begin
                    text = wikitext.data["pages"].first[1]["revisions"][0]["slots"]["main"]["*"]
                    if text.match?(/\|\s*Zona\ssismica\s*=\s*([\dA-B\-]+)/)
                            zonasismica = row[4].value
                            zonesismiche = []
                            zonasismica.to_s.scan(/(\d[A-B]*)\-*/).each { |z| zonesismiche.push(z[0])}
                            matches = []
                            match = text.match(/\|\s*Zona\ssismica\s*=\s*([\dA-B\-]+)/)
                            match[1].to_s.scan(/(\d[A-B]*)\-*/).each { |z| matches.push(z[0])}
                        if matches.join("-") != zonesismiche.join("-")
                            c += 1
                            f.write("#{title},#{matches.join("-")},#{zonesismiche.join("-")}\n")
                            if active
                                text.gsub!(/\|\s*Zona\ssismica\s*=\s*([\dA-B\-]+)/, "|Zona sismica = #{zonesismiche.join("-")}")
                                wikipedia.edit(title: title, text: text, summary: "Correzione del dato della zona sismica (si veda [[Discussioni progetto:Amministrazioni/Comuni italiani#Monitoraggio delle zone sismiche]])", bot: true)
                                puts "Pagina #{title} aggiornata con successo"
                            end
                        end
                    else
                        puts "#{row[3].value.strip} trovato #{title} e non matchabile (#{row[4].value})"
                        m.write("#{title},#{row[4].value}\n")
                        n += 1
                    end
                rescue
                    puts "#{row[3].value.strip} non trovato in ricerca"
                    n += 1
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
    f.close
    m.close
    puts "Elaborati #{tot} comuni di cui #{c} con discrepanze. Ci sono #{n} errori."
end
f.close
m.close
puts "Elaborati #{tot} comuni di cui #{c} con discrepanze Ci sono #{n} errori.."
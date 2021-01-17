require 'mediawiki_api'
require 'roo'
require 'httparty'

wikipedia = MediawikiApi::Client.new("https://it.wikipedia.org/w/api.php")
f = File.open("comuni.csv", "a")
xlsx = Roo::Spreadsheet.open("classificazione2020.xlsx")
xlsx.default_sheet = xlsx.sheets[0]
c = 0
tot = 0
n = 0
url = "https://petscan.wmflabs.org/?format=json&doit=&categories=Comuni%20d%27Italia&depth=5&project=wikipedia&lang=it&templates_yes=divisione%20amministrativa"
petscan = HTTParty.get(url, timeout: 600).to_h["*"][0]["a"]["*"]
begin
    xlsx.each_row_streaming do |row|
        if !row[0].empty? && row[0].value != "Regione"
            tot += 1
            # stringaricerca = 'intitle:"' + row[3].value + '" comune italiano'
            # search = wikipedia.query(list: "search", srsearch: stringaricerca, srlimit: 1)
            if petscan.find { |e| e["title"].include?(row[3].value.gsub(" ", "_"))} != nil
                # title = search.data["search"][0]["title"]
                if petscan.select { |e| e["title"].include?(row[3].value.gsub(" ", "_"))}.count > 1
                    if petscan.find { |e| e["title"] == row[3].value.gsub(" ", "_")} != nil
                        title = petscan.find { |e| e["title"] == row[3].value.gsub(" ", "_")}["title"]
                    elsif petscan.find { |e| e["title"] == "#{row[3].value} (Italia)".gsub(" ", "_")} != nil
                        title = petscan.find { |e| e["title"] == "#{row[3].value} (Italia)".gsub(" ", "_")}["title"]
                    else
                        puts "#{row[3].value} più opzioni"
                        n += 1
                        next
                    end
                else
                    title = petscan.find { |e| e["title"].include?(row[3].value.gsub(" ", "_"))}["title"]
                end
                wikitext = wikipedia.query prop: :revisions, titles: title, rvprop: :content, rvslots: "*"
                begin
                    text = wikitext.data["pages"].first[1]["revisions"][0]["slots"]["main"]["*"]
                    match = text.match(/\|\s*Zona\ssismica\s*=\s*(\d)/)
                    if match != nil
                        if match[1].to_i != row[4].value.to_i
                            c += 1
                            f.write("#{title},#{match[1]},#{row[4].value}\n")
                        end
                    else
                        puts "#{row[3].value} trovato #{title} e non matchabile"
                        n += 1
                    end
                rescue
                    puts "#{row[3].value} non trovato in ricerca"
                    n += 1
                    next
                end
            else 
                puts "#{row[3].value} non trovato"
                n += 1
            end
        end
    end
rescue Interrupt => e 
    puts "Salvo..."
    f.close
    puts "Elaborati #{tot} comuni di cui #{c} con discrepanze. Ci sono #{n} errori."
end
f.close
puts "Elaborati #{tot} comuni di cui #{c} con discrepanze Ci sono #{n} errori.."
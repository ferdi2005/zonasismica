require 'mediawiki_api'
require 'json'

wikipedia = MediawikiApi::Client.new("https://it.wikipedia.org/w/api.php")

wikidata = JSON.parse(File.read("#{__dir__}/wikidata.txt"))
comuni = File.open("#{__dir__}/mancanti.csv", "r").to_a
comuni.each do |c|
    item_req = wikipedia.query(prop: :iwlinks, titles: c.split(",")[0], iwprefix: :d)
    begin
        item = item_req.data["pages"].first[1]["iwlinks"][0]["*"]
        wikidata.delete_if { |e| e[0] == item}
    rescue NoMethodError
        next
    end
end

f = File.open("#{__dir__}/wikidata.txt", "w")
f.write(wikidata.to_json)
f.close

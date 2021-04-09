// https://github.com/maxlath/wikibase-edit/blob/master/docs/how_to.md#set-reference
fs = require('fs')
var sleep = require('sleep'); 

var username = fs.readFileSync(".config", "utf-8").split("\n")[0]
var password = fs.readFileSync(".config", "utf-8").split("\n")[1]
const generalConfig = {
    instance: 'https://www.wikidata.org',
    credentials: {
        username: username,
        password: password
    },
    summary: "Adding seismic zone",
    userAgent: 'FerdiBot/v1.0.0 (https://ferdinando.me; ferdi.traversa@gmail.com)',
    maxlag: 10
}
const wbEdit = require('wikibase-edit')(generalConfig)

var zones = JSON.parse(fs.readFileSync("wikidata.txt", "utf-8"));

matchingZones = {
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

for (z in zones) {
    var zone = zones[z];
    
    await wbEdit.claim.create({
            id: "Q47070",
            property: "P9235",
            value: matchingZones["2"],
            references: [
                { P248: "Q206936"},
                { P854: "http://www.protezionecivile.gov.it/attivita-rischi/rischio-sismico/attivita/classificazione-sismica", P813: new Date().toISOString().split('T')[0]}
            ]
        });

        
        console.log("Updated " + zone[0]);
}

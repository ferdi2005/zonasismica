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
    userAgent: 'ZonaSismicaBot@FerdiBot/v1.0.1 (https://ferdinando.me)'
}
const wbEdit = require('wikibase-edit')(generalConfig);

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

try {
    for (z in zones) {
        var zone = zones[z];
        
        await wbEdit.claim.create({
                id: zone[0],
                property: "P9235",
                value: matchingZones[zone[1]],
                references: [
                    { P248: "Q206936"},
                    { P854: "http://www.protezionecivile.gov.it/attivita-rischi/rischio-sismico/attivita/classificazione-sismica", P813: new Date().toISOString().split('T')[0]}
                ]
            });

            delete zones[z];
            
            console.log("Updated " + zone[0]);
            sleep.sleep(60); // Wait during test
    }
    fs.writeFileSync("new_wikidata.txt", JSON.stringify(zones), "utf8");
} catch (error) {
    fs.writeFileSync("new_wikidata.txt", JSON.stringify(zones), "utf8"); 
}


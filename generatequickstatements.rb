total = []
"1
1-2A
2
2A
2A-2B
2B
2A-3A-3B
2B-3A
3
3S
3A
3A-3B
3B
3-4
4".split("\n").each do |classif|
    total.push('CREATE
	LAST	P31	Q105725387
	LAST	P17	Q38
	LAST	P1448	it:"' + classif + '"
	LAST	Lit	"' + classif + '"
	LAST	Len	"' + classif + '"
	LAST	Dit	"classificazione sismica italiana"
	LAST	Den	"Italian seismic classifiation"'
)
end

puts total.join("\n")

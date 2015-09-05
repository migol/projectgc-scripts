function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in Pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        TableSort(keys, function(a,b) return order(t, a, b) end)
    else
        TableSort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
function expandFilter(filter)
-- add custom groups as types and make excludeTypes accociative
if filter.types~= nil then
    if Type(filter.types)=="string" then
      local tmp=filter.types
      filter.types={}
      TableInsert(filter.types,tmp)
    end
    local types=filter.types
    filter.types={}
    for i,v in IPairs(types) do
      if v=="Physical" then
        TableInsert(filter.types,"Traditional Cache")
        TableInsert(filter.types,"Unknown Cache")
        TableInsert(filter.types,"Multi-cache")
        TableInsert(filter.types,"Letterbox Hybrid")
        TableInsert(filter.types,"Wherigo Cache")
        TableInsert(filter.types,"Project APE Cache")
        TableInsert(filter.types,"Groundspeak HQ")
      elseif v=="Events" then
        TableInsert(filter.types,"Event Cache")
        TableInsert(filter.types,"Cache In Trash Out Event")
        TableInsert(filter.types,"Lost and Found Event Cache")
        TableInsert(filter.types,"Mega-Event Cache")
        TableInsert(filter.types,"Groundspeak Block Party")
        TableInsert(filter.types,"Giga-Event Cache")
        TableInsert(filter.types,"Groundspeak Lost and Found Celebration")
      else
        TableInsert(filter.types,v)
      end
    end
end

-- exclude types
if filter.excludeTypes~= nil then
    if Type(filter.excludeTypes)=="string" then
      local tmp=filter.excludeTypes
      filter.excludeTypes={}
      TableInsert(filter.excludeTypes,tmp)
    end
    local types=filter.excludeTypes
    filter.excludeTypes={}
    for i,v in IPairs(types) do
      if v=="Physical" then
        filter.excludeTypes['Traditional Cache']="Traditional Cache"
        filter.excludeTypes['Unknown Cache']="Unknown Cache"
        filter.excludeTypes['Multi-cache']="Multi-cache"
        filter.excludeTypes['Letterbox Hybrid']="Letterbox Hybrid"
        filter.excludeTypes['Wherigo Cache']="Wherigo Cache"
        filter.excludeTypes['Project APE Cache']="Project APE Cache"
        filter.excludeTypes['Groundspeak HQ']="Groundspeak HQ"
      elseif v=="Events" then
        filter.excludeTypes['Event Cache']="Event Cache"
        filter.excludeTypes['Cache In Trash Out Event']="Cache In Trash Out Event"
        filter.excludeTypes['Lost and Found Event Cache']="Lost and Found Event Cache"
        filter.excludeTypes['Mega-Event Cache']="Mega-Event Cache"
        filter.excludeTypes['Groundspeak Block Party']="Groundspeak Block Party"
        filter.excludeTypes['Giga-Event Cache']="Giga-Event Cache"
        filter.excludeTypes['Groundspeak Lost and Found Celebration']="Groundspeak Lost and Found Celebration"
      else
        filter.excludeTypes[v]=v
      end
    end
end
--split mutli country

if filter.country ~= nil and Type(filter.country)=="table" then
    filter.countries={}
    for i,v in Pairs(filter.country) do
      filter.countries[v]=v
    end
end
--split mutli region

if filter.region ~= nil and Type(filter.region)=="table" then
  filter.regions={}
    for i,v in Pairs(filter.region) do
      filter.regions[v]=v
    end
end
--split mutli county

if filter.county ~= nil and Type(filter.county)=="table" then
	filter.counties={}
    for i,v in Pairs(filter.county) do
      filter.counties[v]=v
    end
end

return filter
end

function GetCombinedFinds(profileId,config)
--replacement for PGC_GetFinds
--the large difference it that filter can be a [] with diffrent parameters.
--The resulting caches are combined and sorted
--additional filter options not includer in PGC_GetFinds can also be added
--minlatitude,maxlatitude, minlongitude, maxlongitude in decimal form

local finds={}

if (config.filter)[1] == nil then
    local tmp=config.filter
    config.filter={}
    TableInsert(config.filter,tmp)
end
local filters=config.filter
for i,c in IPairs(filters) do
	config.filter=expandFilter(c)
    local filter=config.filter
	local res= PGC_GetFinds(profileId,  config)
    local last=#finds+1
    for k,v in IPairs(res) do
      	local fail=false

		if filter.countries ~=nil and filter.countries[v.country]== nil then
  			fail=true
  		end
		if filter.regions ~=nil and filter.regions[v.region]== nil then
  			fail=true
  		end
		if filter.counties ~=nil and filter.counties[v.county]== nil then
  			fail=true
  		end
      	--exculde types
      	if filter.excludeTypes~= nil and filter.excludeTypes[v.type]~= nil then
      		fail=true
        end
      	if filter.minlatitude ~= nil and ToNumber(filter.minlatitude)>=ToNumber(v.latitude) then
        	fail=true
        end
    	if filter.maxlatitude ~= nil and ToNumber(filter.maxlatitude)<=ToNumber(v.latitude) then
        	fail=true
        end
        if filter.minlongitude ~= nil and ToNumber(filter.minlongitude)>=ToNumber(v.longitude) then
        	fail=true
        end
      	if filter.maxlongitude ~= nil and ToNumber(filter.maxlongitude)<=ToNumber(v.longitude) then
        	fail=true
        end
      	if fail==false then
    		finds[last] = v
    		last=last+1
        end
    end
end
local sortFinds={}
for k,v in spairs(finds, function(t,a,b)  if t[b].visitdate==t[a].visitdate then return t[b].log_id >t[a].log_id else return t[b].visitdate>t[a].visitdate  end end) do
    TableInsert(sortFinds,v)
end
return sortFinds
end

local status = { }
local args={...}
conf = args[1].config

if conf.countries == nil then
    conf.countries = 5
else
    conf.countries = ToNumber(conf.countries)
end
if conf.types == nil then
    conf.types = 5
else
    conf.types = ToNumber(conf.types)
end

profileName = args[1]['profileName']
Print('Got profile name, ', profileName, "\n")
profileId = PGC_ProfileName2Id(profileName)
Print('Converted to id ', profileId, "\n")
Print("Countries needed: ", conf.countries, "\n")
Print("Types needed: ", conf.countries, "\n")
local filter={}
filter["country"]=conf.country
myFinds = GetCombinedFinds( profileId, { fields = { 'gccode','cache_name', 'type', 'country','visitdate','log_id' },filter=filter } )

for i, f in IPairs(myFinds) do
    if status[f['country']] == nil then
        status[f['country']] = { }
    end
    if status[f['country']][f['type']] == nil then
        status[f['country']][f['type']] = { }
        status[f['country']][f['type']] = f
    end
end

local okcountries = { }
local num
local numok = 0

for country, types in Pairs(status) do
    num = 0
    for type, gccode in Pairs(types) do
        num = num + 1
    end
    if num >= conf.types then
        okcountries[country] = num
        Print(country, ": ", okcountries[country], "\n")
        numok = numok + 1
    end
end

local ok = false
local log = false
local html = false

if numok >= conf.countries then
    log = "Completed countries:\n"
    ok = true
    for country, number in Pairs(okcountries) do
        log = log .. country .. ": " .. number .. " types.\n"
    	for i,v in Pairs(status[country]) do
      		log=log..v['gccode'].." "..v['type'].." "..v['cache_name'].."\n"
      	end
    	log=log.."\n"
    end
else
    html = "Status so far (" .. numok .. " of " .. conf.countries .. " done):<br>"
    for country, types in Pairs(status) do
        html = html .. country
        if okcountries[country] then
            html = html .. " (OK)"
        end
        html = html .. ": <br>"
    	for i,v in Pairs(status[country]) do
      		html=html..v['gccode'].." "..v['type'].." "..v['cache_name'].."<br>"
      	end

    end
end

return { ok = ok, log = log, html = html }

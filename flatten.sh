#!/bin/bash

# champion.json
json=champion.json
file=$(echo ${json} | sed 's/\.json/.csv/')
sed -i '' 's/-[[:space:]]*/-/g' ${json}

stats=$(jq -r '.data|to_entries|.[0].value.stats|keys|map(".value.stats."+.)|join(",")' ${json})
info=$(jq -r '.data|to_entries|.[0].value.info|keys|map(".value.info."+.)|join(",")' ${json})

echo "name,tag,${info},${stats}" | sed $'s/,/\\\n/g'|awk -F'.' '{print $NF}' | xargs | sed 's/ /,/g' > ${file}
jq --raw-output ".data | to_entries | map([.key,.value.tags[0],${info},${stats}] | map(.|tostring)| join(\",\"))|join(\"\n\")" ${json} >> ${file}

# item.json
json=item.json
file=$(echo ${json} | sed 's/\.json/.csv/')
sed -i '' 's/-[[:space:]]*/-/g' ${json}

stats=$(jq -r '.data|to_entries|map(.value.stats|keys|join("\n"))|join("\n")' ${json} | sed '/^$/d' |sort| uniq)

echo "Name,Gold,$(echo ${stats} | sed 's/ /,/g')" > ${file}
jq -r '.data|to_entries|map(select(.value.stats|length >0)|{name:.value.name,gold:.value.gold.total,stats:.value.stats}|tostring)|join("\n")' ${json}\
|while read line
do
	while read mod
	do
		export ${mod}=0
	done < <(echo -e "${stats}")
	export $(echo ${line} | jq -r '.stats|to_entries|map([.key,.value|tostring]|join("="))[]')
	item=$(echo ${line} | jq -r '[.name,.gold|tostring]|join(",")')
	printf "${item},"
	while read mod
	do
		printf $(eval echo \${${mod}})
		printf ','
	done < <(echo -e "${stats}")
	printf '\n'
done | sed 's/,$//' >> ${file}
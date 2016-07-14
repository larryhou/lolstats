#!/bin/bash

# champion.json
json=champion.json
file=$(echo ${json} | sed 's/\.json/.csv/')
sed -i '' 's/-[[:space:]]*/-/g' ${json}

stats=$(jq -r '.data|to_entries|.[0].value.stats|keys|map(".value.stats."+.)|join(",")' ${json})
info=$(jq -r '.data|to_entries|.[0].value.info|keys|map(".value.info."+.)|join(",")' ${json})

echo "name,tag1,tag2,${info},${stats}" | sed $'s/,/\\\n/g'|awk -F'.' '{print $NF}' | xargs | sed 's/ /,/g' > ${file}
jq --raw-output ".data | to_entries | map([.key,.value.tags[0],.value.tags[1],${info},${stats}] | map(.|tostring)| join(\",\"))|join(\"\n\")" ${json} >> ${file}

# item.json
json=item.json
file=$(echo ${json} | sed 's/\.json/.csv/')
sed -i '' 's/-[[:space:]]*/-/g' ${json}

stats=$(jq -r '.data|to_entries|map(.value.stats|keys|join("\n"))|join("\n")' ${json} | sed '/^$/d' |sort| uniq)

effect=$(jq -r '.data|to_entries|map(.value)|map(select(.effect|length>0)|.effect|to_entries|map(.key)|join("\n"))|join("\n")' ${json} | sort | uniq)

echo "Name,Gold,$(echo -e "${stats}\n${effect}" | xargs | sed 's/ /,/g')" > ${file}
jq -r '.data|to_entries|map(select(.value.stats|length >0)|{name:.value.name,gold:.value.gold.total,stats:.value.stats,effect:.value.effect}|tostring)|join("\n")' ${json}\
|while read line
do
	while read mod
	do
		export ${mod}=0
	done < <(echo -e "${stats}\n${effect}")
	
	export $(echo ${line} | jq -r '.stats|to_entries|map([.key,.value|tostring]|join("="))[]')
	RT_ENV=$(echo ${line} | jq -r '.effect|select(.|length>0)|to_entries|map([.key,.value|tostring]|join("="))[]')
	if [ ! "${RT_ENV}" = "" ]
	then
		export ${RT_ENV}
	fi
	
	item=$(echo ${line} | jq -r '[.name,.gold|tostring]|join(",")')
	printf "${item},"
	while read mod
	do
		printf -- $(eval echo \${${mod}})
		printf -- ','
	done < <(echo -e "${stats}\n${effect}"| sed '/^[[:space:]]*$/d')
	printf '\n'
done | sed 's/,$//' >> ${file}
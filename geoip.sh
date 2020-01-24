#!/bin/bash

if hash jq 2>/dev/null;
then
	bl_name="Green Group"
		
	declare -a curlArgs=('-H' "Accept: */*"  '-H' "Accept-Encoding: gzip, deflate" '-H' "Content-Type: application/json" '-H' "X-Account-Context: xxxx")
	
	function get_auth {
	
		#echo "$3"
		
		httpMethod=$1
		requestUrl=$2
		requestBody=$3
		
		APIID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
		APIKEY="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
	
		AUTH_TYPE="ARMOR-PSK"
	
		url=`echo -n $requestUrl | sed 's@http:@https:@g'`
		requestUri=`printf '/';echo -n $url | cut -d '/' -f4-`
		host=`echo $requestUrl | cut -d '/' -f3`
		req=`echo -n $requestUri | cut -d '?' -f1`
		queryString=`echo -n $requestUri | cut -d '?' -f2-`
		if [ $httpMethod = 'GET' ] 
		then
			requestBody=''
		else
			encrequestBody=`echo -n "$3" | openssl sha512 | awk '{print$2}' | xxd -r -p | base64 -w0`
			requestBody="$encrequestBody"
		fi
			
		timestamp=`date +%s`
		nonce=$(uuidgen)
		requestData=`printf $APIID$httpMethod$req$nonce$timestamp$requestBody`
		mac=`echo -n $requestData | openssl sha512 -hmac $APIKEY | awk '{print$2}'`
		signature=`echo -n $mac | xxd -r -p | base64 -w0`
		authHeader=`printf "$AUTH_TYPE $APIID:$signature:$nonce:$timestamp"`
		
		if [ ! -z "$requestBody" ]
		then
			response=`curl -X $httpMethod \
				"${curlArgs[@]}" \
				-H "Authorization: $authHeader" \
				--data-raw "$3" \
				$requestUrl 2>/dev/null`
		else
			response=`curl -X $httpMethod \
				"${curlArgs[@]}" \
				-H "Authorization: $authHeader" \
				$requestUrl 2>/dev/null`
		fi
		unset requestBody
	}
	
	get_auth 'GET' 'https://api.armor.com/firewalls' ''
	
	
	sites=$(echo $response | jq -r '.[]' | jq '{id: .vcdOrgVdcId,loc: .name, devid: .id, devloc: .location}')
	
	for row in $(echo "$sites" | jq -r '.|[.id, .loc, .devid, .devloc] | @csv'); do
		siteId=$(echo "${row}" | awk -F ',' '{print$1}')
		siteName=$(echo "${row}" | awk -F ',' '{print$2}')
		devID=$(echo "${row}" | awk -F',' '{print$3}')
		devLoc=$(echo "${row}" | awk -F',' '{print$4}')
		get_auth "GET" "https://api.armor.com/firewall/$siteId/groups" ""
		groups=$(echo $response | jq -r 'map(select(.name == "'"$bl_name"'"))' | jq -c '.[]|.id')
		if [[ $groups == '' ]]
		then
			body="{\"type\":\"group\",\"name\":\"$bl_name\",\"deviceId\":$devID,\"location\":$devLoc,\"values\":$(jq -R -s -c 'split("\n") | map(select(length > 0))' out.json)}"
			httpmethod="POST"
			url="https://api.armor.com/firewall/$siteId/groups/"
		else
			body="{\"type\":\"group\",\"name\":\"$bl_name\",\"deviceId\":$devID,\"location\":$devLoc,\"values\":$(jq -R -s -c 'split("\n") | map(select(length > 0))' out.json),\"id\":$siteId,\"description\":null}"
			httpmethod="PUT"
			url="https://api.armor.com/firewall/$siteId/groups/$groups"
		fi
		
		get_auth "$httpmethod" "$url" "$body"
		
		echo $(date -d @$timestamp) >> trace.out
		echo "$httpmethod" >> trace.out
		echo "$url" >> trace.out
		echo "$body" >> trace.out

		echo $response
	done
		
	printf "\r\n"
else
	echo "You need to have jq installed. You can do so by typing the following: apt install jq or yum install jq"
	exit 1
fi

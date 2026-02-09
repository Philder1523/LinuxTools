#!/usr/bin/bash

webSite=$1;

checkRaggiungibilità() {
		if ping "$(nslookup $1 | grep "Address" | tail -n 1 | awk "{print $2}")"; then
			echo "il sito è raggiungibile";
		else
			echo "il sito non è raggiungibile";
		fi
}

checkCertificato(){
	if curl -Iv https://www.$1/ 2>&1 | grep "SSL certificate"; then
			echo "";
			echo "il sito è sicuro";
	else
		echo "il certificato non è valido. Non visitare questo sito"
	fi
}



if command -v nslookup > /dev/null; then
		checkSitoWeb "$webSite";
	else
		sudo apt update;
		sudo apt install dnsutils;
		which nslookup;
		checkSitoWeb "$webSite";
fi

if command -v whois > /dev/null; then
	if command -v curl > /dev/null; then
			echo "Informazioni sul sito: "
			echo "";
			whois "$webSite" | head;
			echo "";
			echo "";
			checkCertificato "$webSite";
		else
			sudo apt update;
			sudo apt-get install curl;
			which curl;
			checkCertificato "$webSite";
	fi

	else
		sudo apt update;
		sudo apt install whois;
fi



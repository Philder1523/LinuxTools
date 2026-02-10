#!/usr/bin/bash

webSite=$1;
echo -e "\n\nControllo del sito web $webSite...";

checkRaggiungibilità() {
		if ping -c 1 "$1" > /dev/null 2>&1; then
			echo "✅ il sito è raggiungibile";
		else
			echo "❌ il sito non è raggiungibile";
		fi
}

checkCertificato(){
	if curl -Iv https://www."$1"/ 2>&1 | grep "SSL certificate"; then
			echo "";
			echo "✅ il sito è sicuro";
	else
		echo "❌ il certificato non è valido. Non visitare questo sito"
	fi
}

if command -v ping > /dev/null; then
		checkRaggiungibilità "$webSite";
	else
		sudo apt update;
		sudo apt install iputils-ping;
		which ping;
		checkSitoWeb "$webSite";
fi

if command -v whois > /dev/null; then
	if command -v curl > /dev/null; then
			echo -e "Informazioni sul sito: \n"
			whois "$webSite" | head;
			echo -e "\n";
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



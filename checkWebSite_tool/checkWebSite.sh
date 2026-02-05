webSite=$1;

if command -v whois > /dev/null; then
  if command -v curl > /dev/null; then
	echo "Informazioni sul sito: "
	echo "";
	whois $webSite | head;
	echo "";
	echo "";
	if curl -Iv https://www.$webSite/ 2>&1 | grep "SSL certificate"; then
    	   echo "";
           echo "il sito è sicuro";
	else
	   echo "il certificato non è valido. Non visitare questo sito"
	fi
  fi
fi



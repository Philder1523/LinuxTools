#!/usr/bin/bash

APT_UPDATED=false

check_and_install() {
    local command_name=$1
    local package_name=$2

    if command -v "$command_name" > /dev/null; then
        return 0 # Command is already installed
    fi

    echo "Command '$command_name' not found. Attempting to install '$package_name'..."

    if ! $APT_UPDATED; then
        echo "Running sudo apt update..."
        sudo apt update
        APT_UPDATED=true
    fi

    sudo apt install -y "$package_name"
    return $? # Return the exit code of the install command
}

webSite=$1;
echo -e "\n\nControllo del sito web $webSite...";

checkRaggiungibilità() {
    local domain=$1
    local reachable=false

    echo "Verifica raggiungibilità di rete (ping)..."
    if ping -c 1 "$domain" > /dev/null 2>&1; then
        echo "✅ Rete: il sito è raggiungibile via ping.";
        reachable=true
    else
        echo "❌ Rete: il sito non è raggiungibile via ping.";
    fi

    if $reachable; then
        echo "Verifica disponibilità server web (curl)..."
        if command -v curl > /dev/null; then
            # Check for HTTP status code (2xx or 3xx for redirects)
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://www.$domain")
            if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
                echo "✅ Server Web: il sito risponde con codice HTTP $http_code.";
            else
                echo "❌ Server Web: il sito non risponde correttamente (Codice HTTP: $http_code).";
            fi
        else
            echo "⚠️ Curl non è installato per un controllo approfondito del server web.";
        fi
    fi

    if ! $reachable; then
        echo "❌ Il sito non è raggiungibile o non risponde correttamente.";
    fi
}

checkCertificato(){
    local domain=$1
    local cert_valid=false

    if command -v openssl > /dev/null; then
        # Try to get certificate dates using openssl
        cert_dates=$(echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
        
        if [ -n "$cert_dates" ]; then
            not_before_str=$(echo "$cert_dates" | grep notBefore | cut -d= -f2)
            not_after_str=$(echo "$cert_dates" | grep notAfter | cut -d= -f2)

            not_before_epoch=$(date -d "$not_before_str" +%s)
            not_after_epoch=$(date -d "$not_after_str" +%s)
            current_epoch=$(date +%s)

            if (( current_epoch >= not_before_epoch && current_epoch <= not_after_epoch )); then
                echo "✅ Il certificato SSL è valido e non scaduto (scade il $not_after_str)";
                cert_valid=true
            else
                echo "❌ Il certificato SSL non è valido o scaduto (valido da $not_before_str a $not_after_str).";
            fi
        else
            echo "⚠️ Impossibile ottenere dettagli sul certificato con openssl. Fallback a controllo curl."
        fi
    fi

    if ! $cert_valid; then
        # Fallback/additional check using curl
        echo "Effettuando controllo SSL base con curl..."
        if curl -I --silent --globoff "https://www.$domain" 2>&1 | grep -q "SSL certificate verify ok."; then
            echo "✅ il sito è sicuro (controllo base curl)";
            cert_valid=true
        elif curl -I --silent --globoff "http://www.$domain" 2>&1 | grep -q "Location: https"; then
            echo "✅ Il sito reindirizza a HTTPS (controllo base curl)";
            cert_valid=true
        else
            echo "❌ Il certificato non è valido o non rilevato. Non visitare questo sito"
        fi
    fi
}

if check_and_install "ping" "iputils-ping"; then
    checkRaggiungibilità "$webSite"
fi

if check_and_install "whois" "whois"; then
    if check_and_install "curl" "curl"; then
        if check_and_install "openssl" "openssl"; then
            echo -e "Informazioni sul sito: \n"
            whois "$webSite" | head;
            echo -e "\n";
            checkCertificato "$webSite";
        else
            echo "❌ openssl non disponibile per un controllo certificato avanzato."
            # Fallback to basic curl check if openssl isn't available
            checkCertificato "$webSite";
        fi
    fi
fi
#!/usr/bin/bash
rete=$1;
echo -e "\n\nControllo della rete locale... ";

if command -v fping > /dev/null; then
        fping -agq "$rete/24" >/dev/null;
    else
        echo "⚠️ fping non è installato. Installalo per un controllo più efficiente della rete locale.";
        sudo apt update && sudo apt install fping;
        fping -agq "$rete/24";
fi

echo -e "\n\nEcco gli indirizzi IP attivi nella rete locale: \n";
arp -a | grep -v "incomplete";

touch /mnt/localNetworkScan.txt;
arp -a | grep -v "incomplete" > /mnt/localNetworkScan.txt;

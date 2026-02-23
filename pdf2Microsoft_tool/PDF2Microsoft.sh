#/bin/bash

file=$1
choice=0

if command -v libreoffice; then
  echo -e "Ciao, in quale formato vuoi convertire il tuo file pdf?\n\n1. file Word(.docx)\n\n2. file Excel(.csv)";
  read choice;

  if choiche == 1; then
    echo "conversione del file nel formato docx...";
    libreoffice --headless --infilter="writer_pdf_import" --convert-to docx "$file";
    echo -e "\n\nil file pdf è stato convertito in file docx!";
  fi

  if choice == 2; then
    echo "conversione del file nel formato csv....";
    libreoffice --headless --convert-to csv nomefile.pdf
    echo -e "\n\nil file pdf è stato convertito in file csv!"
else
  sudo apt update;
  sudo apt-get install libreoffice;
fi

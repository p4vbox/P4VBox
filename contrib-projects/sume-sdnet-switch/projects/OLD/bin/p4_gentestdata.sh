#!/bin/bash

source ${SUME_SETTINGS}
cd ${P4_PROJECT_DIR} && make gen_testdata

# tcpdump options:
#   -r file_in : file indica arquivo pcap a ser lido
#   -n : não converte endereços para nome
#   -e : Imprima o cabeçalho no nível do link em cada linha de despejo. Isso pode ser usado, por exemplo, para imprimir endereços de camada MAC para protocolos como Ethernet
#   -XX : Ao analisar e imprimir, além de imprimir os cabeçalhos de cada pacote, imprima os dados de cada pacote, incluindo seu cabeçalho de nível de link, em hexadecimal e ASCII.
#   -t  : Não printa o timestamp
#   -tt : Printa timestamp em forma de data
#   -vvv : printa informações adicionais dos protocolos como o checksun
#   -l | tee file_out : copia para o buffer stdout (mostra no terminal e grava no file_out em formato ASCII)
echo #
echo ---------------- Pkts_in and Pkts_expect ------------------
cd ${P4_PROJECT_DIR}/testdata && tcpdump -r src.pcap -n -e -# -XX -t -vvv -l | tee ${P4_PROJECT_DIR}/log/Pkts_in.txt
cd ${P4_PROJECT_DIR}/testdata && tcpdump -r dst.pcap -n -e -# -XX -t -vvv -l | tee ${P4_PROJECT_DIR}/log/Pkts_expect.txt

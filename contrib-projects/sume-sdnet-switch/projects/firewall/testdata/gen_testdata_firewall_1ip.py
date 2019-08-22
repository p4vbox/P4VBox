#!/usr/bin/env python

#
# Copyright (c) 2019 Mateus Saquetti
# All rights reserved.
#
# This software was developed by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
#
# Description:
#              Modified to generate multiple testdatas for virtual switches
# Create Date:
#              19.06.2019
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#


from nf_sim_tools import *
import random
from collections import OrderedDict
import sss_sdnet_tuples

NUM_PKTS = 8
NUM_VLANS = 1

###########
# pkt generation tools
###########

pktsApplied = []
pktsExpected = []

# Pkt lists for SUME simulations
nf_applied = OrderedDict()
nf_applied[0] = []
nf_applied[1] = []
nf_applied[2] = []
nf_applied[3] = []
nf_expected = OrderedDict()
nf_expected[0] = []
nf_expected[1] = []
nf_expected[2] = []
nf_expected[3] = []

nf_port_map = {"nf0":0b00000001, "nf1":0b00000100, "nf2":0b00010000, "nf3":0b01000000, "dma0":0b00000010}
nf_id_map = {"nf0":0, "nf1":1, "nf2":2, "nf3":3}
inv_nf_id_map = {0:"nf0", 1:"nf1", 2:"nf2", 3:"nf3"}

sss_sdnet_tuples.clear_tuple_files()

def applyPkt(pkt, ingress, time):
    pktsApplied.append(pkt)
    sss_sdnet_tuples.sume_tuple_in['pkt_len'] = len(pkt)
    sss_sdnet_tuples.sume_tuple_in['src_port'] = nf_port_map[ingress]
    sss_sdnet_tuples.sume_tuple_expect['pkt_len'] = len(pkt)
    sss_sdnet_tuples.sume_tuple_expect['src_port'] = nf_port_map[ingress]
    pkt.time = time
    nf_applied[nf_id_map[ingress]].append(pkt)

def expPkt(pkt, egress, drop):
    pktsExpected.append(pkt)

    sss_sdnet_tuples.sume_tuple_expect['drop'] = drop
    if ( drop ):
        sss_sdnet_tuples.sume_tuple_expect['dst_port'] = 0b00000000
    else:
        sss_sdnet_tuples.sume_tuple_expect['dst_port'] = nf_port_map[egress]

    sss_sdnet_tuples.write_tuples()
    if egress in ["nf0","nf1","nf2","nf3"] and drop == False:
        nf_expected[nf_id_map[egress]].append(pkt)
    elif egress == 'bcast' and drop == False:
        nf_expected[0].append(pkt)
        nf_expected[1].append(pkt)
        nf_expected[2].append(pkt)
        nf_expected[3].append(pkt)

def write_pcap_files():
    wrpcap("src.pcap", pktsApplied)
    wrpcap("dst.pcap", pktsExpected)

    for i in nf_applied.keys():
        if (len(nf_applied[i]) > 0):
            wrpcap('nf{0}_applied.pcap'.format(i), nf_applied[i])

    for i in nf_expected.keys():
        if (len(nf_expected[i]) > 0):
            wrpcap('nf{0}_expected.pcap'.format(i), nf_expected[i])

    for i in nf_applied.keys():
        print "nf{0}_applied times: ".format(i), [p.time for p in nf_applied[i]]

def printPacketsParam(i, fb, sH, dH, sL4, dL4):
    print("")
    print("Packet id:\tBlock:\t\tSource:\t\tDestination:\tSport L4:\tDport L4:")
    print("Packet "+ str(i) +"\t"+str(fb)+"\t\tHost"+str(sH)+"      --> "+"\tHost"+str(dH)+"\t\t"+sL4+"       --> "+"\t"+dL4)

#####################
# generate testdata #
#####################
# Topology:
#                   Left                                       Right
#           H1 ------------------- |    SUME_SWITCH    | ------------------- H2
#           |                    Port1               Port2                   |
#           |               Port1 = 0b00000100 | Port2 = 0b00010000          |
#   H1(MAC) = 00:00:01:00:00:01                                      H2(MAC) = 00:00:01:00:00:04
#    H1(IP) = 192.168.0.1                                             H2(IP) = 10.0.0.1
#    H1(L4) = 4444 or 1234                                            H2(L4) = 1111
#
#                   Firewall lock policy:
# +---------------------------------------------------------+
# |         UNLOCKED          |           LOCKED            |
# +---------------------------+-----------------------------+
# |         H1 -> H2          |          H1 -> H2           |
# |       1234 -> 1111        |        4444 -> 1111         |
# +---------------------------+-----------------------------+
# |         H2 -> H1          |          H2 -> H1           |
# |       1111 -> 4444        |        1111 -> 1234         |
# +---------------------------+-----------------------------+

MAC_addr = {}
MAC_addr[nf_id_map["nf0"]] = "00:00:00:01:00:00"
MAC_addr[nf_id_map["nf1"]] = "00:00:00:01:00:01"
MAC_addr[nf_id_map["nf2"]] = "00:00:00:01:00:02"
MAC_addr[nf_id_map["nf3"]] = "00:00:00:01:00:03"

IP_addr = {}
IP_addr[nf_id_map["nf0"]] = "10.0.1.0"
IP_addr[nf_id_map["nf1"]] = "10.0.1.1"
IP_addr[nf_id_map["nf2"]] = "10.0.1.2"
IP_addr[nf_id_map["nf3"]] = "10.0.1.3"

L4_addr = {}
L4_addr["firewall_src"] = "4444"
L4_addr["firewall_dst"] = "1234"
L4_addr["host_2"] = "1111"

vlan_id = 3
vlan_prio = 0
firewall_block = True

# create some packets
for i in range(NUM_PKTS):
    # Definning priority:
    vlan_prio += 1
    if ( vlan_prio > 4 ):
        vlan_prio = 1

    # Switch host source and setting MAC address:
    host_src = random.randint(1,2)

    if host_src == 1:
        host_dst = 2
    elif host_src == 2:
        host_dst = 1

    src_MAC = MAC_addr[host_src]
    dst_MAC = MAC_addr[host_dst]

    # Firewall block logic:
    firewall_block = not(firewall_block)

    if ( firewall_block ):
        if ( 1 == host_src ):
            src_L4 = L4_addr["firewall_src"]
            dst_L4 = L4_addr["host_2"]

        elif ( 2 == host_src ):
            src_L4 = L4_addr["host_2"]
            dst_L4 = L4_addr["firewall_dst"]
    else:
        if ( 1 == host_src ):
            src_L4 = L4_addr["firewall_dst"]
            dst_L4 = L4_addr["host_2"]
        elif ( 2 == host_src ):
            src_L4 = L4_addr["host_2"]
            dst_L4 = L4_addr["firewall_src"]

    printPacketsParam(i, firewall_block, host_src, host_dst, src_L4, dst_L4)

    # generete ping packet = IP( , ttl=20) / ICMP()
    pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=IP_addr[host_src], dst=IP_addr[host_dst], ttl=20) / TCP(sport=int(src_L4), dport=int(dst_L4))
    pkt = pad_pkt(pkt, 64)
    ingress = inv_nf_id_map[host_src]
    egress = inv_nf_id_map[host_dst]
    applyPkt(pkt, ingress, i)
    expPkt(pkt, egress, firewall_block)

print("\n")
write_pcap_files()

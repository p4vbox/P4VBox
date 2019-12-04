#!/usr/bin/env python

#
# Copyright (c) 2017 Stephen Ibanez
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
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
##################################################################################
# This software was modified by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
#
# Modified by:
#       Mateus Saquetti
#
# Description:
#       Modified to generate multiple testdatas for virtual switches
#
# Create date:
#       02.11.2018
#
# Additional Comments:
#
#
##################################################################################


from nf_sim_tools import *
import random, numpy
from collections import OrderedDict
import sss_sdnet_tuples

NUM_PKTS = 8
NUM_VLANS = 1
LEN_PKT = 256
# Time between packets
ENTER_RATE = 1

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

def expPkt(pkt, egress):
    pktsExpected.append(pkt)
    sss_sdnet_tuples.sume_tuple_expect['dst_port'] = nf_port_map[egress]
    sss_sdnet_tuples.write_tuples()
    if egress in ["nf0","nf1","nf2","nf3"]:
        nf_expected[nf_id_map[egress]].append(pkt)
    elif egress == 'bcast':
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

#####################
# generate testdata #
#####################
MAC_addr = {}
MAC_addr[nf_id_map["nf0"]] = "00:18:3e:02:0d:a0"
MAC_addr[nf_id_map["nf1"]] = "00:18:3e:02:0d:a1"
MAC_addr[nf_id_map["nf2"]] = "00:18:3e:02:0d:a2"
MAC_addr[nf_id_map["nf3"]] = "00:18:3e:02:0d:a3"

IP_addr = {}
IP_addr[nf_id_map["nf0"]] = "10.0.1.0"
IP_addr[nf_id_map["nf1"]] = "10.0.1.1"
IP_addr[nf_id_map["nf2"]] = "10.0.1.2"
IP_addr[nf_id_map["nf3"]] = "10.0.1.3"

src_pkts = []
dst_pkts = []

vlan_id = 1
vlan_prio = 0

# create some packets
for i in range(NUM_PKTS):
    src_ind = random.randint(1,2)

    if src_ind == 1:
        dst_ind = 2
    elif src_ind == 2:
        dst_ind = 1

    src_MAC = MAC_addr[src_ind]
    dst_MAC = MAC_addr[dst_ind]

    if vlan_prio > 4:
        vlan_prio = 1
    else :
        vlan_prio += 1

    # generete ping packet = IP( , ttl=20) / ICMP()
    pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=IP_addr[src_ind], dst=IP_addr[dst_ind], ttl=20) / UDP(sport=20415, dport=1234) / ('a'*(LEN_PKT-46))
    pkt = pad_pkt(pkt, LEN_PKT)
    ingress = inv_nf_id_map[src_ind]
    egress = inv_nf_id_map[dst_ind]
    applyPkt(pkt, ingress, i)
    expPkt(pkt, egress)


write_pcap_files()

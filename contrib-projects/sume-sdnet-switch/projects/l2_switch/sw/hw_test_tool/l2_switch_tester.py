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

import os, sys, re, cmd, subprocess, shlex, time, random, socket, struct
import numpy as np
from threading import Thread
from collections import OrderedDict

from nf_sim_tools import *

"""
Test Network Topology:

(MAC_addr_H0)             (MAC_addr_SPort0) (MAC_addr_SPort3)             (MAC_addr_H3)
(IP_addr_H0)                    nf0                 nf3                   (IP_addr_H3)
          H0 ------------------- |                   | ------------------- H3
                                 |    SUME SWITCH    |
          H1 ------------------- |                   | ------------------- H2
(IP_addr_H1)                    nf1                 nf2                   (IP_addr_H2)
(MAC_addr_H1)             (MAC_addr_SPort1) (MAC_addr_SPort2)             (MAC_addr_H2)
"""


IFACE_H0 = "eth0" # network interface down
IFACE_H1 = "eth1" # network interface up
IFACE_H2 = "eth2" # network interface up
IFACE_H3 = "eth3" # network interface up
sender = IFACE_H0 # the network interface of the sender

VLANS = 1
VLAN_ID = 1
MAX_PKT_SIZE = 1000 # maximum packet size (in bytes)
MIN_PKT_SIZE = 64   # minimum packet size (in bytes)
DEF_PKT_SIZE = 256  # default packet size (in bytes)
HEADER_SIZE = 42    # size of Ether/IP/UDP headers
SMALL_FLOW = 20     # size of small flow by send_all
BIG_FLOW = 1000     # size of big flow by send_all

dest_host_map = {0:1, 1:0, 2:3, 3:2} # dictionary to map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology

MAC_addr_H = {} # MAC of Hosts H[0, 1, 2, 3] connected to SUME Ports nf[0, 1, 2, 3] respectively
MAC_addr_H[0] = "08:11:11:11:11:08"
MAC_addr_H[1] = "08:22:22:22:22:08"
MAC_addr_H[2] = "08:33:33:33:33:08"
MAC_addr_H[3] = "08:44:44:44:44:08"
# MAC_addr_H[4] = "4c:ed:fb:42:09:94"

IP_addr_H = {} # IP of Hosts connected to nf0, nf1, nf2, nf3 respectively. Not used in this case!
IP_addr_H[0] = "10.0.1.0"
IP_addr_H[1] = "10.0.1.1"
IP_addr_H[2] = "10.0.1.2"
IP_addr_H[3] = "10.0.1.3"


class L2SwitchTester(cmd.Cmd):
    """A HW testing tool for the l2_switch design"""

    prompt = "testing> "
    intro = "The HW testing tool for the l2_switch design\n type help to see all commands"

    def _get_rand_IP(self):
        return socket.inet_ntoa(struct.pack('>I', random.randint(1, 0xffffffff)))

    def _get_rand_port(self):
        return random.randint(1, 0xffff)

    def _make_flow(self, flow_size, src_ind):
        pkts = []
        srcIP = self._get_rand_IP()
        dstIP = self._get_rand_IP()
        sport = self._get_rand_port()
        dport = self._get_rand_port()
        payload_size = MIN_PKT_SIZE
        vlan_prio = 0
        # make the data pkts
        while payload_size <= flow_size:
            pkt = Ether(src=MAC_addr_H[src_ind], dst=MAC_addr_H[dest_host_map[src_ind]]) / Dot1Q(vlan=VLAN_ID, prio=vlan_prio) / IP(src=srcIP, dst=dstIP, ttl=20) / UDP(sport=sport, dport=dport) / ((payload_size - HEADER_SIZE)*"A")
            pkt = pad_pkt(pkt, payload_size)
            pkts.append(pkt)
            payload_size += MIN_PKT_SIZE
        return pkts

    def _make_packet(self, flow_size, src_ind):
        srcIP = self._get_rand_IP()
        dstIP = self._get_rand_IP()
        sport = self._get_rand_port()
        dport = self._get_rand_port()
        # make the data pkts
        vlan_prio = 0
        pkt = Ether(src=MAC_addr_H[src_ind], dst=MAC_addr_H[dest_host_map[src_ind]]) / Dot1Q(vlan=VLAN_ID, prio=vlan_prio) / IP(src=srcIP, dst=dstIP, ttl=20) / UDP(sport=sport, dport=dport) / ((flow_size - HEADER_SIZE)*"A")
        pkt = pad_pkt(pkt, flow_size)
        return pkt

    """
    Generate a trace of flows indicated by the given parameters and apply to the switch
    """
    def _run_flows(self, num_flows, min_size, max_size, src_host):
        trace = []
        flow_pkts = []
        for fid in range(num_flows):
            flow_size = random.randint(min_size, max_size)
            # create the flows pkts
            print("\nFlow "+ str(fid) + " size: " + str(flow_size))
            flow_pkts = self._make_flow(flow_size, src_host)
            # apply trace to the switch
            sendp(flow_pkts, iface=sender)


    def _parse_line(self, line):
        args = line.split()
        if (len(args) != 4):
            print >> sys.stderr, "ERROR: usage..."
            self.help_run_flows()
            return (None, None, None, None)
        try:
            num_flows = int(args[0])
            min_size = int(args[1])
            max_size = int(args[2])
            src_host = int(args[3])
            if ((src_host < 0) or (src_host > 3)):
                print >> sys.stderr, "ERROR: src_host must be in topology"
                return (None, None, None, None)
        except:
            print >> sys.stderr, "ERROR: all arguments must be valid integers"
            return (None, None, None, None)

        return (num_flows, min_size, max_size, src_host)

    def do_run_flows(self, line):
        (num_flows, min_size, max_size, src_host) = self._parse_line(line)
        if (num_flows is not None and min_size is not None and max_size is not None and src_host is not None):
            self._run_flows(num_flows, min_size, max_size, src_host)

    def help_run_flows(self):
        print """
run_flows <num_flows> <min_size> <max_size> <src_host>
DESCRIPTION: Create a trace simulating some number of distinct UDP flows beginnign with MIN_PKT_SIZE
to flow_size, all running simultaneously and apply the resulting packets to the switch. The flow_size (in
bytes) of each flow will be randomly chosen between <min_size> and <max_size>.
    <num_flows> : the number of concurrent active flows to run through the switch
    <min_size>  : the minimum possible size of each flow
    <max_size>  : the maximum possible size of each flow, must be 0, 1, 2 or 3
    <src_host>  : the number of source host sender of packet, based on topology:\n
(MAC_addr_H0)             (MAC_addr_SPort0) (MAC_addr_SPort3)             (MAC_addr_H3)
(IP_addr_H0)                    nf0                 nf3                   (IP_addr_H3)
          H0 ------------------- |                   | ------------------- H3
                                 |    SUME SWITCH    |
          H1 ------------------- |                   | ------------------- H2
(IP_addr_H1)                    nf1                 nf2                   (IP_addr_H2)
(MAC_addr_H1)             (MAC_addr_SPort1) (MAC_addr_SPort2)             (MAC_addr_H2)
"""

    """
    Generate a simple packets with size indicated by parameters and apply to the switch
    """
    def _gen_packets(self, pkts_num, pkts_size, src_host):
        for fid in range(pkts_num):
            pkt = self._make_packet(pkts_size, src_host)
            # apply trace to the switch
            if src_host == 0:
                sender = IFACE_H0
            elif src_host == 1:
                sender = IFACE_H1
            elif src_host == 2:
                sender = IFACE_H2
            elif src_host == 3:
                sender = IFACE_H3
            else:
                print >> sys.stderr, "ERROR: usage..."
            sendp(pkt, iface=sender)

    def _parse_line_gen_packets(self, line):
        args = line.split()
        if (len(args) != 3):
            print >> sys.stderr, "ERROR: usage..."
            self.help_gen_packets()
            return (None, None, None)
        try:
            pkts_num = int(args[0])
            pkts_size = int(args[1])
            src_host = int(args[2])
            if ((src_host < 0) or (src_host > 3)):
                print >> sys.stderr, "ERROR: src_host must be in topology"
                return (None, None, None)
        except:
            print >> sys.stderr, "ERROR: all arguments must be valid integers"
            return (None, None, None)

        return (pkts_num, pkts_size, src_host)

    def do_gen_packets(self, line):
        (pkts_num, pkts_size, src_host) = self._parse_line_gen_packets(line)
        if (pkts_num is not None and pkts_size is not None and src_host is not None):
            self._gen_packets(pkts_num, pkts_size, src_host)

    def help_gen_packets(self):
        print """
run_flows <pkts_num> <pkts_size> <src_host>
DESCRIPTION: Create a trace simulating some number of distinct UDP flows beginnign with exactly flow_size
and apply the resulting packets to the switch based in the given src_host, if src_host the packet is send by
interface especificated by IFACE_H0, so on.
    <pkts_num>  : the number of packets to send to the switch
    <pkts_size> : the exactly payload of packet (in bytes)
    <src_host>  : the number of source host sender of packet, based on topology:\n
(MAC_addr_H0)             (MAC_addr_SPort0) (MAC_addr_SPort3)             (MAC_addr_H3)
(IP_addr_H0)                    nf0                 nf3                   (IP_addr_H3)
          H0 ------------------- |                   | ------------------- H3
                                 |    SUME SWITCH    |
          H1 ------------------- |                   | ------------------- H2
(IP_addr_H1)                    nf1                 nf2                   (IP_addr_H2)
(MAC_addr_H1)             (MAC_addr_SPort1) (MAC_addr_SPort2)             (MAC_addr_H2)
"""

    def run_batch(self, pkt_size, flow_type):
        pkts = []
        flow_size = self._get_size(flow_type)
        for i in range(20):
            if pkt_size is not None:
                if ((i >= 0) and (i < 5)) :
                    src_host = 0
                elif ((i >= 5) and (i < 10)) :
                    src_host = 1
                elif ((i >= 10) and (i < 15)) :
                    src_host = 2
                elif ((i >= 15) and (i < 20)) :
                    src_host = 3
                pkts.append(self._make_packet(pkt_size, src_host))
        flow_sent = flow_size/20
        for it in range(flow_sent):
            sendp(pkts, iface=sender)

    def _get_size(self, flow_type):
        if flow_type == 'small':
            return SMALL_FLOW
        if flow_type == 'big':
            return BIG_FLOW

    def do_send_all(self, line):
        try:
            self.run_batch(DEF_PKT_SIZE, line)
        except KeyboardInterrupt:
            return

    def complete_send_all(self, text, line, begidx, endidx):
        choice = ['big', 'small']
        if not text:
            completions = choice
        else:
            completions = [ r for r in choice if r.startswith(text)]
        return completions

    def help_send_all(self):
        print """
send_all <type>
DESCRIPTION: simulation of all hosts in topology sending packets. The flows are sent in batches of 20 (5 per host).
    Supported types are:
        small : a small flow will be generated ("""+SMALL_FLOW+""" packets)
        big   : a big flow will be generated ("""+BIG_FLOW+""" packets)\n
(MAC_addr_H0)             (MAC_addr_SPort0) (MAC_addr_SPort3)             (MAC_addr_H3)
(IP_addr_H0)                    nf0                 nf3                   (IP_addr_H3)
      H0 ------------------- |                   | ------------------- H3
                             |    SUME SWITCH    |
      H1 ------------------- |                   | ------------------- H2
(IP_addr_H1)                    nf1                 nf2                   (IP_addr_H2)
(MAC_addr_H1)             (MAC_addr_SPort1) (MAC_addr_SPort2)             (MAC_addr_H2)
"""

    def do_exit(self, line):
        print ""
        return True

if __name__ == '__main__':
    if len(sys.argv) > 1:
        L2SwitchTester().onecmd(' '.join(sys.argv[1:]))
    else:
        L2SwitchTester().cmdloop()

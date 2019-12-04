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

# echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6

import os, sys, re, cmd, subprocess, shlex, time, random, socket, struct
import numpy as np
from threading import Thread
from collections import OrderedDict

from nf_sim_tools import *

class ViewTest(cmd.Cmd):

    """A simple HW testing tool to listen to the ethernet ports"""

    prompt = "testing> "
    intro = "The HW testing tool for listen to the ethernet ports\n type help to see all commands"

    def _parse_line(self, line):
        args = line.split()
        if (len(args) != 1):
            print >> sys.stderr, "ERROR: usage..."
            self.help_run_flows()
            return (None)
        try:
            iface = args[0]
        except:
            print >> sys.stderr, "ERROR: all arguments must be valid"
            return (None)
        return (iface)

    def do_listen(self, line):
        iface = self._parse_line(line)
        if (iface is not None):
            try:
                subprocess.call(["tcpdump", "-n", "-e", "-#", "-XX", "-t", "-v", "-i", iface ])
            except KeyboardInterrupt:
                return


    def help_listen(self):
        print """
listen <eth_name>
DESCRIPTION: Listen the ethrnet interface especificated by <eth_name>.
    <eth_names> : the name of the ethernet interface to listen
"""

    def do_exit(self, line):
        print ""
        return True

if __name__ == '__main__':
    if len(sys.argv) > 1:
        ViewTest().onecmd(' '.join(sys.argv[1:]))
    else:
        ViewTest().cmdloop()
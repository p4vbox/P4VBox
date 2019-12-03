Copyright (c) 2019 Mateus Saquetti
All rights reserved.

This software was developed by Institute of Informatics of the Federal
University of Rio Grande do Sul (INF-UFRGS)

Description:
             Simple readme for P4VBox
Create Date:
             31.05.2019

@NETFPGA_LICENSE_HEADER_START@

Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
license agreements.  See the NOTICE file distributed with this work for
additional information regarding copyright ownership.  NetFPGA licenses this
file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
"License"); you may not use this file except in compliance with the
License.  You may obtain a copy of the License at:

  http://www.netfpga-cic.org

Unless required by applicable law or agreed to in writing, Work distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

@NETFPGA_LICENSE_HEADER_END@


How to clone this repo:

git clone https://github.com/mateussaquetti/P4VBox.git

git pull --tags


Add this lines at your enviroment viriables file (~/.bashrc)

#### P4VBox #####
export P4VBOX=~/projects/P4VBox/scripts/settings.sh
source ${P4VBOX}


How to create a new P4VBox project:
$ $P4_NEWPROJ <name_project>

Like this:
$ $P4_NEWPROJ l2_switch

Modify the p4vbox_settings.sh with the correctly P4_PROJECT_NAME
Write yours p4 program (with extension <name_p4_switch>.p4) on src/ folder
Write your commands file with topology (witch name: commands_<name_p4_switch>.txt)
Write your gen_testdata.py (with name: gen_testdata_<num_of_parallel_p4_switchs>ip.py)
Modify the nf_datapath.v replecing <P4_SWITCH> with each name of p4 modules. Add new instances if necessary (with name: nf_datapath_<num_of_parallel_p4_switchs>ip.v)
Modify the nf_datapath.v with correctly signals of p4_switch_ip from IPI and signals to OPI
In templates/sss_wraper folder, replace <p4_switch> with the name of each p4_switch instance in name of nf_sdnet_<p4_switch>.v file and into this file! Create new  nf_sdnet_<p4_switch>.v if necessary.

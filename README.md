Copyright (c) 2019 Mateus Saquetti
All rights reserved.

This software was developed by Institute of Informatics of the Federal
University of Rio Grande do Sul (INF-UFRGS)

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

## P4VBox

P4 Virtual Box (P4VBox) Forwarding Engine is a Hard-Virtualization (HDL-hypervisor) solution to programmable data planes. It enables virtualization by directly defining a parallel architecture for accommodating multiple programmable switch programs and their individual on FPGA-based devices [NetFPGA SUME](https://reference.digilentinc.com/reference/programmable-logic/netfpga-sume/start).

To more info, please see the links:
[P4VBox: Enabling P4-Based Switch Virtualization](https://ieeexplore.ieee.org/document/8895999)
[Virtualization in Programmable Data Plane: A Survey and Open Challenges](https://ieeexplore.ieee.org/abstract/document/9078127)
[NetFPGA SUME Datasheet](https://reference.digilentinc.com/_media/sume:netfpga-sume_rm.pdf)

The source code of the P4VBox forwarding engine is a fork of [P4-NetFPGA Project](https://github.com/NetFPGA/P4-NetFPGA-public) and use Xilinx P4-SDNet toolchain. Kindly note that this code is under development and may be unstable.

To more info about dependencies and installation:
[P4->NetFPGA - Getting Started](https://github.com/NetFPGA/P4-NetFPGA-public/wiki/Getting-Started)
[NetFPGA Project - Reference Operating System Setup Guide](https://github.com/NetFPGA/NetFPGA-SUME-public/wiki/Reference-Operating-System-Setup-Guide)


### Installation Ubuntu 16.04

How to clone this repository:

```sh
$  git clone https://github.com/p4vbox/P4VBox.git
$  git pull --tags
```

Add these lines at your environment variables file: `vi ~/.bashrc`

```sh
export P4VBOX=~/projects/P4VBox/scripts/settings.sh
source $P4VBOX
```

Updating environment:

```sh
$  source ~/.bashrc
```

Instaling all dependencies:

```sh
$  sudo $P4VBOX_SCRIPTS/tools/setup_SUME.sh  
```

Making the library and installing the SUME driver:

```sh
$  $P4VBOX_MAKE_LIBRARY
$  $P4VBOX_INSTALL_DRIVER
```

### Usage

How to create a new P4VBox project:

```sh
$  $P4VBOX_NEWPROJ <project_name>
```

Update environment variables, change the `$P4VBOX_SCRIPTS/settings.sh` with the correct project name: `vi $P4VBOX`

```sh
...
export P4_PROJECT_NAME=<project_name>
...
```

Then update the environment with the new project name:

```sh
$  source $P4VBOX
```

#### Building a project - P4 switches Flow

Enter in the project folder to create virtual switches:

```sh
$  cd $P4_PROJECT_DIR
```

Write:
  - The virtual switch in P4 code (.p4), for example, on `src/` folder.
  - The commands file `commands_<name_p4_switch>.txt` with switch tables.
  - The script generator for data tes on `testdata/` folder. **Warning:** *each switch should have a test data named: `gen_testdata_<switch_name>.py` and your project must have your propely test data named: gen_testdata_<project_name>.py*

#### Running the Project - P4 switches Flow

Generate your test data, you can run this option with `--pp` option to see the packets:

```sh
cd $P4VBOX_SCRIPTS

$  ./p4vbox.py <virtual_switch_0> <virtual_switch_1> .. <virtual_switch_N> -name <project_name> -t
```

Verify your P4 Code sintaxe:

```sh
$  ./p4vbox.py <virtual_switch_0> <virtual_switch_1> .. <virtual_switch_N> -name <project_name> -c
```

Run the P4 switch simulation, you can run `-v` flag to see in terminal, the standart output is the log file in `$P4_PROJECT_DIR/log/`:

```sh
$  ./p4vbox.py <virtual_switch_0> <virtual_switch_1> .. <virtual_switch_N> -name <project_name> -s
```

Run the SUME simulation to all virtual switches:

```sh
$  ./p4vbox.py <virtual_switch_0> <virtual_switch_1> .. <virtual_switch_N> -name <project_name>
```

Implement your design:

```sh
$  ./p4vbox.py <virtual_switch_0> <virtual_switch_1> .. <virtual_switch_N> -name <project_name> --imp
```

Programming the SUME board:

```sh
$  sudo $P4VBOX_PROGSUME
```

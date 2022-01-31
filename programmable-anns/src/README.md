Copyright (c) 2019

All rights reserved.

Part of this software was developed by Stanford University and the University of Cambridge Computer Laboratory under National Science Foundation under Grant No. CNS-0855268,
the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
as part of the DARPA MRC research programme.

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



## Programmable ANNs

Source code of the Programmable ANNs engine. Kindly note that this code is under development and may be unstable. For a running example, please consider using the code in the NNP4-build/ or NNP4_2vS-build/ folder.

### Installation Ubuntu 16.04

How to clone this repository:

```sh
$  git clone https://github.com/programmable-ann/programmable-anns.git
$  git pull --tags
```

### Usage

Copy those projects to P4VBox projects folder and run:

```sh
$  cd $P4VBOX_SCRIPTS
$  ./p4vbox.py NNP4_S1 -name NNP4 --imp
```


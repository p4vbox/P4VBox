## Build

This folder contains a functional build of the Programmable ANNs, for use with a NNP4_S1 and NNP4_S2. There are bitstreams in the bitfiles/ folder and a simple python tester in tools/ folder.

### Requirements
In order to run this build is necessary a SUME board properly installed on a host. **Only** if the SUME driver isn't available, run with root permission:

```sh
$  source settings.sh
$  cd tools
$  ./setup_env.sh
```

### Usage
In order to program the SUME board, issue the following command:

```sh
$  source settings.sh
$  cd bitfiles
$  ./run_me.sh NNP4_2vS.bit
```

#### Test

To test the design, is requirement another machine send and receiving packets from 10G NIC, another SUME board with reference_nic design loaded or a bridge switch to translate electrical signals to optical.

In order to view packets from SUME board, issue the following command and type help to more information(require tcpdump installed):

```sh
$  cd tools
$  ./view_packets.py
```
To send packets, run and type help to more information:
```sh
$  ./NNP4_tester_2vS.py
```

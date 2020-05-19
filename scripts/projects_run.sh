#!/bin/bash

./p4vbox.py l2_switch -name l2_band --imp

./p4vbox.py router -name router_band --imp

./p4vbox.py l2_switch l2_switch -name l2_l2_band --imp

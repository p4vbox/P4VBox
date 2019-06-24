#!/bin/bash

cp -v ./settings.sh $SUME_FOLDER/tools/settings.sh
source $SUME_SETTINGS

# Fix files for run 2 parallel P4 IPs
cp -v $P4_PROJECT_DIR/testdata/gen_testdata_LR_2ip.py $P4_PROJECT_DIR/testdata/gen_testdata_LR.py
cp -v $NF_DESIGN_DIR/hw/hdl/nf_datapath_2ip.v $NF_DESIGN_DIR/hw/hdl/nf_datapath.v
cp -v $NF_DESIGN_DIR/hw/tcl/simple_sume_switch_2ip.tcl $NF_DESIGN_DIR/hw/tcl/simple_sume_switch.tcl
cp -v $NF_DESIGN_DIR/hw/tcl/simple_sume_switch_sim_2ip.tcl $NF_DESIGN_DIR/hw/tcl/simple_sume_switch_sim.tcl

cd $SUME_SDNET/projects/bin/ && ./p4_clean.sh
cd $P4_PROJECT_DIR && mkdir log
export P4_SWITCH_BASE_ADDR=0x44020000

export P4_SWITCH=LR
echo ---------------- Gen_TESTDATA P4: ${P4_SWITCH} ------------------
cd $SUME_SDNET/projects/bin/ && ./p4_gentestdata.sh 2>&1 | tee $P4_PROJECT_DIR/log/log_1-gen_testdata_P4_${P4_SWITCH}.txt

export P4_SWITCH=l2_switch
echo ---------------- Gen_SRC P4: ${P4_SWITCH} ------------------
cd $P4_PROJECT_DIR && make gen_src 2>&1 | tee ${P4_PROJECT_DIR}/log/log_2-build_P4_${P4_SWITCH}.txt

export P4_ID=0
export SDNET_OUT_DIR=nf_sume_sdnet_${P4_ID}_ip
echo ---------------- Compile P4: ${P4_SWITCH} - ${P4_ID} ------------------
cd $P4_PROJECT_DIR && make compile 2>&1 | tee -a $P4_PROJECT_DIR/log/log_2-build_P4_${P4_SWITCH}.txt
echo ------------- Biuld IP: ${P4_SWITCH} - ${P4_ID} ------------
cd $SUME_SDNET/projects/bin/ && ./p4_build_ip.sh 2>&1 | tee -a $P4_PROJECT_DIR/log/log_2-build_P4_${P4_SWITCH}.txt
echo ------------- Install IP: ${P4_SWITCH} - ${P4_ID} ------------
cd $P4_PROJECT_DIR && make install_sdnet 2>&1 | tee $P4_PROJECT_DIR/log/log_3-install_IPs_${P4_SWITCH}.txt

export P4_SWITCH=router
echo ---------------- Gen_SRC P4: ${P4_SWITCH} ------------------
cd $P4_PROJECT_DIR && make gen_src 2>&1 | tee $P4_PROJECT_DIR/log/log_2-build_P4_${P4_SWITCH}.txt

export P4_ID=1
export SDNET_OUT_DIR=nf_sume_sdnet_${P4_ID}_ip
echo ---------------- Compile P4: ${P4_SWITCH} - ${P4_ID} ------------------
cd $P4_PROJECT_DIR && make compile 2>&1 | tee -a $P4_PROJECT_DIR/log/log_2-build_P4_${P4_SWITCH}.txt
echo ------------- Biuld IP: ${P4_SWITCH} - ${P4_ID} ------------
cd $SUME_SDNET/projects/bin/ && ./p4_build_ip.sh 2>&1 | tee -a $P4_PROJECT_DIR/log/log_2-build_P4_${P4_SWITCH}.txt
echo ------------- Install IP: ${P4_SWITCH} - ${P4_ID} ------------
cd $P4_PROJECT_DIR && make install_sdnet 2>&1 | tee $P4_PROJECT_DIR/log/log_3-install_IPs_${P4_SWITCH}.txt


echo ------------------- CONFIG WRITES ----------------------
rm -v ${P4_PROJECT_DIR}/config_writes/config_writes.txt 2>&1 | tee -a ${P4_PROJECT_DIR}/log/log_2-config_writes.txt
cat ${P4_PROJECT_DIR}/config_writes/IP* 2>&1 | tee -a ${P4_PROJECT_DIR}/config_writes/config_writes.txt ${P4_PROJECT_DIR}/log/log_2-config_writes.txt
cd $P4_PROJECT_DIR && make gen_config_writes 2>&1 | tee -a ${P4_PROJECT_DIR}/log/log_2-config_writes.txt


echo ------------------- SUME SIMULATION ----------------------
cd ${P4_PROJECT_BIN} && ./p4_sim_sume.sh 2>&1 | tee -a ${P4_PROJECT_DIR}/log/log_4-sim_sume.txt
# cd ${P4_PROJECT_BIN} && ./open_sim_gui.sh


echo ------------------- SYNTHESIS AND INPLEMENTATION ----------------------
cd ${P4_PROJECT_BIN} && ./p4_synth_impl.sh 2>&1 | tee -a $P4_PROJECT_DIR/log/log_5-sume_synthesis.txt

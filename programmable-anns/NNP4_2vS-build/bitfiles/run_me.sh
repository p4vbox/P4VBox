if [ $# -ne 1 ]; then
  echo
  echo "Usage: $0 [bistream_file]"
  echo
  echo " e.g. $0 NNP4_2vS.bit"
  echo
  echo " This script program the SUME board with the bitstream,"
	echo " end initializes the switch tables."
	echo
  exit 1
fi

bitimage=$1
bitname=${1%.bit}

${SUME_SDNET}/tools/program_switch.sh $bitimage config_writes_${bitname}.sh

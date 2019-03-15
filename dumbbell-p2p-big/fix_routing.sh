#!/bin/bash

. experiment.sh

h=$(hostname)
h1=${h%%.*}
if [ $h1 != router-1 ]; then
	./run ssh router-1 "cd $expdir; ./fix_routing.sh"
	# echo 'must execute on router-1'
	exit -1
fi

# execute on router-1
sudo ip route del 10.0.0.0/8
sudo ip route add 10.0.8.0/24   via 10.0.11.2
sudo ip route add 10.0.9.0/24   via 10.0.11.2
sudo ip route add 10.0.10.0/24  via 10.0.11.2

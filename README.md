# deterlab experimentation script

### What is it?
Script to be run on your own PC, which first uploads whole folder to deterlab in
experiments folder by using rsync tool, then it logs in to deterlab with ssh and executes given
command on remote users.isi.deterlab.net PC.

### Usage:

##### List of commands:
```
./run upload - uploads whole folder to /users/<username>/experiments/<exp_name>/
./run make_exp - creates containerized experiment (dozen of virtual machines per single physical)
./run make_normal_exp - creates non containerized experiment (real machines, no virtualization)
./run terminate - terminates experiment
./run swapin - swaps in experiment
./run swapout - swaps out experiment
./run reboot - reboot nodes (doesn't really work well, doesn't reconnect network)
./run ping - ping all nodes listed in experiment.sh
./run orchestrate - runs gen-aal.sh script which generates aal file which is then ran with orchestrator
./run experiment - same as ./run orchestrate ; ./run download @monitor (downloads data from monitor nodes)
./run download [<node-name>|<@group>] - can download results from single node or group of nodes
./run ssh [<node-name>|<@group>] [<command>] [shell] - depending on given parameters it logs in to node,
	@group argument can only be used in other mode which requires given <command>, which is then executed
	on all nodes in given group.
./run ssh - logs in to users.isi.deterlab.net
```

##### Steps to create and run experiment:
1. edit experiment.sh (set user name, project name, experiment name, node list)
1. edit topology.tcl (edit network layout)
1. edit gen-aal.sh (edit experiment orchestration script)
1. put shared files in data folder
1. ./run make_exp
1. ./run swapin
1.	wait at least 10 minutes (until network is ready for use)
1. ./run experiment
1. look in archives folder for results



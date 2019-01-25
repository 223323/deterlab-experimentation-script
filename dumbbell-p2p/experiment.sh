user=ftnunsaa
proj=DOSTRACE
exp=dumbbell-p2p2

containerize_params="--pnode-type bpc2133"
#containerize_params=

#######################################
############## NODES ##################
#######################################
servers=""
clients=""

# clients
for i in clientnode-{1..9}; do
	clients="$clients, $i"
done
clients=${clients:1}
##

# attackers
for i in clientnode-{10..10}; do
	attackers="$attackers, $i"
done
attackers=${attackers:1}


# servers
tcpdump_expr=""
for i in servernode-{1..3}; do
	servers="$servers, $i"
	# tcpdump_expr="$tcpdump_expr or host $i"
done
##

servers=${servers:1}
tcpdump_expr=${tcpdump_expr:4}

routers="router-1, router-2"
monitor="$clients, $routers, $attackers, $servers"
nodes="$clients, $routers, $attackers, $servers"




#######################################
aal=orchestrator.aal
topology=topology.tcl
home=/users/$user
gen_aal="gen-aal.sh"
ssh_addr="$user@users.isi.deterlab.net"
deterhome="$ssh_addr:$home"
exp_path="experiments/$exp"
exp_dir=$home/$exp_path
expdir=$exp_dir
datadir=$exp_dir/data
outdir=$exp_dir/output
archivedir=$exp_dir/archive
mods=/share/magi/modules
#######################################

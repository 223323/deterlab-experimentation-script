user=ftnunsaa
proj=DOSTRACE
exp=dumbbell-p2p-big-2

# containerize_params="--pnode-type bpc2133 --packing=12"
containerize_params="--pnode-type bpc2133 --packing=14"
#containerize_params=
function join { local d=", "; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

#######################################
############## NODES ##################
#######################################
tcpdump_expr=""
clients=$(join clientnode-{1..19})
attackers=$(join clientnode-{20..20})
servers=$(join servernode-{1..3})

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

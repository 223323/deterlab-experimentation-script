user=ftnunsaa
proj=DOSTRACE
exp=dumbbell-lan-big
containerize_params="--pnode-type bpc2133 --packing=12"

function join { local d=", "; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

### NODES
clients=$(join clientnode-{1..95})
attackers=$(join clientnode-{96..100})
servers=$(join servernode-{1..5})

tcpdump_expr=""
tcpdump_expr=${tcpdump_expr:4}

routers="router-1, router-2"
monitor="$clients, $routers, $attackers, $servers"
nodes="$clients, $routers, $attackers, $servers"

######################################
aal=orchestrator.aal
topology=topology.tcl
gen_aal=gen-aal.sh

home=/users/$user
remote_hostname=users.isi.deterlab.net
ssh_addr="$user@$remote_hostname"
deterhome="$ssh_addr:$home"

exp_path="experiments/$exp"
exp_dir=$home/$exp_path

expdir=$exp_dir
datadir=$exp_dir/data
outdir=$exp_dir/output
archivedir=$exp_dir/archive
mods=/share/magi/modules
#############################

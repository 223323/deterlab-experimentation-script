export user=ftnunsaa
export proj=DOSTRACE
export exp=client-server1
export name='simple-test'
export gen_aal='gen-aal.py'
export containerize_params="--pnode-type bpc2133"


export clients=`join clientnode`
# export attackers=`join clientnode-20`
export servers=`join servernode`
# export routers="router-1, router-2"

export monitor="$clients, $servers"
export nodes="$clients, $servers"

export tcpdump_expr=""
export tcpdump_expr=${tcpdump_expr:4}

export user=ftnunsaa
export proj=DOSTRACE
export exp=dumbbell-lan-big
# export containerize_params="--pnode-type bpc2133 --packing=12"
export containerize_params="--pnode-type MicroCloud,dl380g3 --packing=12"
export name='dumbell-lan-big'
export gen_aal=gen-aal.py

export allow_attackers=1

if [ $allow_attackers == 0 ]; then

	### NODES
	#export clients=`join clientnode-{1..95}`
	export clients=`join clientnode-{1..100}`
	export attackers=""
	#export attackers=`join clientnode-{96..100}`
	export servers=`join servernode-{1..5}`

	export tcpdump_expr=""
	export tcpdump_expr=${tcpdump_expr:4}

	export routers=router-1,router-2
	export some_clients=`join clientnode-{90..95}`
	#export monitor=$some_clients,$routers,$attackers,$servers
	export monitor=$some_clients,$routers,$servers
	#export nodes=$clients,$routers,$attackers,$servers
	export nodes=$clients,$routers,$servers

elif [ $allow_attackers == 1 ]; then

	### NODES (with attackers)
	export clients=`join clientnode-{1..95}`
	export attackers=`join clientnode-{96..100}`
	export servers=`join servernode-{1..5}`

	export tcpdump_expr=""
	export tcpdump_expr=${tcpdump_expr:4}

	export routers=router-1,router-2
	export some_clients=`join clientnode-{90..95}`
	export monitor=$some_clients,$routers,$attackers,$servers
	export nodes=$clients,$routers,$attackers,$servers

fi

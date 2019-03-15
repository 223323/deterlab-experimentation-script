set ns [new Simulator] 
source tb_compat.tcl 

set magi_start "sudo python /share/magi/current/magi_bootstrap.py" 

# dumbbell topology

# LAN1 ---bottleneck--- LAN2

set num_clients 100
set num_servers 5

set router(1) [$ns node]
set router(2) [$ns node]

tb-set-node-startcmd $router(1) "$magi_start"
tb-set-node-startcmd $router(2) "$magi_start"

set c_lan ""
set s_lan ""

# left side
for {set i 1 } {$i <= $num_clients } { incr i } {  
	set clientnode($i) [$ns node]
	tb-set-node-startcmd $clientnode($i) "$magi_start" 
	append c_lan "$clientnode($i) "
} 

# right side
for {set i 1 } {$i <= $num_servers } { incr i } {  
	set servernode($i) [$ns node]
	tb-set-node-startcmd $servernode($i) "$magi_start" 
	append s_lan "$servernode($i) "
} 

set lanClients [$ns make-lan "$router(1) $c_lan" 100Mb 0ms]
set lanServers [$ns make-lan "$router(2) $s_lan" 100Mb 0ms]

set linkRouters [$ns duplex-link $router(1) $router(2) 100Mb 0ms DropTail]


$ns rtproto Static
$ns run

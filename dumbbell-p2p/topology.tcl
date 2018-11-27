set ns [new Simulator] 
source tb_compat.tcl 

set magi_start "sudo python /share/magi/current/magi_bootstrap.py" 

# dumbbell topology

set num_clients 10
set num_servers 3

set router(1) [$ns node]
set router(2) [$ns node]

tb-set-node-startcmd $router(1) "$magi_start"
tb-set-node-startcmd $router(2) "$magi_start"


set l 0

# left side
for {set i 1 } {$i <= $num_clients } { incr i; incr l } {  
	set clientnode($i) [$ns node]
	tb-set-node-startcmd $clientnode($i) "$magi_start" 
	set link$l [$ns duplex-link $clientnode($i) $router(1) 100Mb 0ms DropTail]
} 

# right side
for {set i 1 } {$i <= $num_servers } { incr i; incr l } {  
	set servernode($i) [$ns node]
	tb-set-node-startcmd $servernode($i) "$magi_start" 
	set link$l [$ns duplex-link $servernode($i) $router(2) 100Mb 0ms DropTail]
} 

set link$l [$ns duplex-link $router(1) $router(2) 100Mb 0ms DropTail]


$ns rtproto Static
$ns run

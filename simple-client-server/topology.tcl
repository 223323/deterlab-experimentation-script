set ns [new Simulator]
source tb_compat.tcl
set clientnode [$ns node]
set servernode [$ns node]
set magi_start "sudo python /share/magi/current/magi_bootstrap.py" 
tb-set-node-startcmd $clientnode "$magi_start"
tb-set-node-startcmd $servernode "$magi_start"
set link [$ns duplex-link $clientnode $servernode 100Mbps 0ms DropTail]

$ns rtproto Static
$ns run

set ns [new Simulator] 
source tb_compat.tcl 

for {set i 0} {$i < 4} {incr i} {
	set nodes($i) [$ns node]
}

set link [$ns duplex-link $nodes(0) $nodes(1) 100Mbps 0ms DropTail] 
set link1 [$ns duplex-link $nodes(1) $nodes(2) 100Mbps 0ms DropTail]
set link2 [$ns duplex-link $nodes(2) $nodes(3) 100Mbps 0ms DropTail]

$ns rtproto Static
$ns run

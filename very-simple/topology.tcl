set ns [new Simulator] 
source tb_compat.tcl 

for {set i 0} {$i < 4} {incr i} {
set nodes($i) [$ns node]
}


$ns rtproto Static
$ns run

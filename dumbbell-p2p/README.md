# Dumbbell-p2p

![dumbbell-lan-diagram](https://github.com/223323/deterlab-experimentation-script/raw/assets/doc/dumbbell-p2p-diagram.png)

1. ./run make_exp
1. ./run swapin
1. wait at least 10 minutes for network to go up
1. ./fix_routing.sh (this will fix bad routing table which was set up by deterlab)
1. ./run experiment (runs experiments, and downloads results, only waiting is required, unless there are errors due to
	network not being up)
1. look for results in archives folder named as output-*date*

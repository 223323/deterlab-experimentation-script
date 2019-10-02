#!/usr/bin/env bash
cmd=$1
shift
. run

case $cmd in
	preprocess)
		cd /tmp/
		rm -rf output
		rm -f *.cap* *.gz *.json collect.log
		;;
	postprocess)
		cd /tmp/
		find -regextype sed -regex '.*\.cap[0-9]*' -exec gzip {} \;
		mkdir -p output
		mv *.gz *.txt output/
		ip addr > output/ipaddr.txt
		;;
esac

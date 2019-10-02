#!/usr/bin/env bash

if [ $1 == preprocess ]; then
	cd /tmp/
	rm -rf output
	rm -f *.cap*
	rm -f *.json
	rm -f collect.log
	# echo "cleanup" > collect.log
elif [ $1 == postprocess ]; then
	# compress cap files
	cd /tmp/ ; find -regextype sed -regex '.*\.cap[0-9]*' -exec gzip {} \;
	mkdir -p output
	mv *.gz output/
	mv *.txt output/
	ip addr > output/ipaddr.txt
fi

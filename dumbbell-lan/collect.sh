#!/usr/bin/env bash

. ${0%/*}/experiment.sh

if [ _$1 == _cleanup ]; then
	cd /tmp/
	rm -rf output
	rm -f *.cap*
	rm -f *.json
	rm -f collect.log
	# echo "cleanup" > collect.log
else
	# compress cap files
	cd /tmp/ ; find -regextype sed -regex '.*\.cap[0-9]*' -exec gzip {} \;
fi

#!/bin/bash
action=$1

if [ "$action" == "-d" ]; then
	unameOut="$(uname -s)"
	case "${unameOut}" in
	    Darwin*)    machine=Mac;;
	    *)          machine="Other"
	esac

	if [ "$machine" == "Mac" ]; then
		base64 --decode
	else 
		base64 -d
	fi
else
	base64
fi

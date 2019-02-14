wd () {
	local wdusage="wd [-h] [alias|option] -- Custom warp directory function for bash (because I don't care much for zsh)
	
	usages:
		wd alias -- cds to the entry associated with alias
		wd show [dir] -- shows aliases for directory specified or \$PWD
		wd path alias -- shows the path associated with the given alias
		wd add:
			wd add sourcedir alias -- adds sourcedir to warp points under alias
			wd add alias -- adds \$PWD to warp points under alias
		wd rm:
			wd rm alias -- removes warp points called alias
			wd rm -d [dir] -- removes warp points linked to dir or \$PWD if unspecified
		wd ls -- list all warp points stored"
	declare -a reserved=("add" "rm" "ls" "show" "-h" "path")
	case "$1" in
		add)
			if [ $# -eq 3 ]; then
				local warpconflict=$(grep -E ^$3: ~/.warprc)
				if [ -n "$warpconflict" ]; then 
					printf "Warp point alias $3 already exists\n$warpconflict\n"
					return 1
				fi
				echo "$3:$(realpath $2)" >> ~/.warprc	
				echo "Added warppoint to $(realpath $2) with alias $3."
			elif [ $# -eq 2 ]; then
				local warpconflict=$(grep -E ^$2: ~/.warprc)
				if [ -n "$warpconflict" ]; then 
					printf "Warp point alias $2 already exists\n$warpconflict\n"
					return 1
				fi
				echo "$2:$PWD" >> ~/.warprc
				echo "Added warppoint to $PWD with alias $2."
			else
				printf "wd add: Expected 1-2 additional arguments: alias or sourcedir alias\n$wdusage\n" >&2
				return 1
			fi
			;;
		rm)
			if [ $# -lt 2 ]; then
				printf "wd rm: Expected at least one argument for alias to delete\n$wdusage\n" >&2
				return 1
			fi
			if [ "$2" = "-d" ]; then
				if [ -z "$3" ]; then
					# tfw $PWD forward slashes and sed syntax don't play well
					sed -iE "/:$(echo $PWD | sed 's/\//\\\//g')\$/d" ~/.warprc	
				else
					sed -iE "/:$(realpath $3 | sed 's/\//\\\//g')\$/d" ~/.warprc	
				fi
			else
				for i in "${@:2}"; do
					echo "Deleting alias $i..."
					sed -i "/^$i:/d" ~/.warprc
				done
			fi
			;;
		ls)
			cat ~/.warprc
			;;
		show)
			if [ $# -gt 1 ]; then
				grep -E ":$(realpath $2)$" ~/.warprc | cut -d ":" -f 1
			else
				grep -E ":$PWD$" ~/.warprc | cut -d ":" -f 1
			fi
			;;
		path)
			(test $# -gt 1 && grep -E "^$2:" ~/.warprc | cut -d ":" -f 2) || 
				(echo "wd path: Expected alias\n$wdusage\n" >&2; return 1)
			;;
		-h)
			echo "$wdusage"
			;;
		*) 
			local warpfind=$(grep -Em 1 ^$1: ~/.warprc | cut -d ":" -f 2)
			if [ -z "$warpfind" ]; then
				printf "Unknown alias: %s\n" "$1" >&2
				echo "For help, use -h" >&2
				return 1
			fi
			echo "Warpdrive [$PWD -> $warpfind]"
			# ~ is a shell expansion that doesn't work when stored in a variable; do a substitution
			cd "${warpfind//\~/$HOME}"
			;;
	esac
}


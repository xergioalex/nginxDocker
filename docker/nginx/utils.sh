# Printer with shell colors
function utils.printer {
	# BASH COLORS
	GREEN=`tput setaf 2`
	RESET=`tput sgr0`
	if [[ ! -z "$2" ]]; then
		# print new line before
    	echo ""
    fi
    echo -e "${GREEN}$1${RESET}"
}  


# Create enviroment files if don't exists
function utils.check_envs_files {
	ENV_FILES=("$@")
	for i in "${ENV_FILES[@]}";  do
		if [[ ! -f "$i" ]]; then
			cp "$i.example" "$i"
		fi
	done
}


# Load environment vars in root directory
function utils.load_environment {
	if [[ ! -z $(cat .env | xargs)  ]]; then
	    set -a
		source .env
		set +a
	fi
}

# Load environment vars in root directory
function utils.current_folder_name {
	echo $(pwd | grep -o '[^/]*$') | tr "[:upper:]" "[:lower:]"
}

# Calcule host ip
function utils.get_host_ip {
	export SERVICE_NGINX_DOCKERHOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)
}
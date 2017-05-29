# Utils functions
. utils.sh

# Create envs vars if don't exist
ENV_FILES=("docker-compose.yaml" ".env" "nginx/site.template" "nginx/site.template.ssl")
utils.check_envs_files "${ENV_FILES[@]}"

# Load environment vars, to use from console, run follow command: 
utils.load_environment 

# Menu options
if [[ "$1" == "machine.create" ]]; then
    utils.printer "Cheking if remote machine exist..."
    # If machine doesn't exist, create a droplet and provision machine
    if [[ "$MACHINE_DRIVER" == "digitalocean" ]]; then
        if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
            utils.printer "Starting machine if it's off..."
            docker-machine start $MACHINE_NAME
            utils.printer "Creating machine..."
            docker-machine create --driver digitalocean --digitalocean-access-token $DIGITAL_ACCESS_TOKEN --digitalocean-image $DIGITAL_IMAGE --digitalocean-size $DIGITAL_SIZE $MACHINE_NAME
            utils.printer "Machine created at: $(docker-machine ip $MACHINE_NAME)"
        else
            utils.printer "Starting machine if it's off..."
            docker-machine start $MACHINE_NAME
            utils.printer "Machine already exist at: $(docker-machine ip $MACHINE_NAME)"
        fi
    elif [[ "$MACHINE_DRIVER" == "virtualbox" ]]; then
        if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
            utils.printer "Creating machine..."
            docker-machine create -d virtualbox $MACHINE_NAME 
            utils.printer "Machine created at: $(docker-machine ip $MACHINE_NAME)"
        else
            utils.printer "Starting machine if it's off..."
            docker-machine start $MACHINE_NAME
            utils.printer "Machine already exist at: $(docker-machine ip $MACHINE_NAME)"
        fi
    fi
elif [[ "$1" == "machine.details" ]]; then
    utils.printer "Searching for machine details..."
    if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
        utils.printer "Machine doesn't exist"
    else
        utils.printer "Machine driver: $MACHINE_DRIVER"
        utils.printer "Machine name: $MACHINE_NAME"
        utils.printer "Machine ip: $(docker-machine ip $MACHINE_NAME)"
    fi
elif [[ "$1" == "machine.start" ]]; then
    if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
        utils.printer "Machine doesn't exist"
    else
        utils.printer "Power on machine..."
        docker-machine rm $MACHINE_NAME
    fi
elif [[ "$1" == "machine.restart" ]]; then
    if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
        utils.printer "Machine doesn't exist"
    else
        utils.printer "Restarting on machine..."
        docker-machine restart $MACHINE_NAME
    fi
elif [[ "$1" == "machine.stop" ]]; then
    if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
        utils.printer "Machine doesn't exist"
    else
        utils.printer "Power off machine..."
        docker-machine stop $MACHINE_NAME
    fi
elif [[ "$1" == "machine.rm" ]]; then
    if [[ "$MACHINE_NAME" != $(docker-machine ls -q | grep "^$MACHINE_NAME$") ]]; then
        utils.printer "Machine doesn't exist"
    else
        utils.printer "Power off machine..."
        docker-machine stop $MACHINE_NAME
        utils.printer "Removing machine..."
        docker-machine rm $MACHINE_NAME
    fi
elif [[ "$1" == "config" ]]; then
    utils.printer "Set nginx configuration..."
    docker-machine ssh $MACHINE_NAME mkdir -p /opt/nginx/config/
    if [[ "$2" == "secure" ]]; then
        docker-machine scp nginx/site.template.ssl $MACHINE_NAME:/opt/nginx/config/default.conf
    else
        docker-machine scp nginx/site.template $MACHINE_NAME:/opt/nginx/config/default.conf
    fi
    utils.printer "Creating logs files..."
    docker-machine ssh $MACHINE_NAME mkdir -p /opt/nginx/logs/
    docker-machine ssh $MACHINE_NAME touch /opt/nginx/logs/site.meteor.access
    docker-machine ssh $MACHINE_NAME touch /opt/nginx/logs/site.flask.access
    docker-machine ssh $MACHINE_NAME touch /opt/nginx/logs/site.meteor.error
    docker-machine ssh $MACHINE_NAME touch /opt/nginx/logs/site.flask.error
    if [[ "$2" == "secure" ]]; then
        utils.printer "Stopping nginx machine if it's running..."
        docker-compose $(docker-machine config $MACHINE_NAME) stop nginx
        utils.printer "Creating letsencrypt certifications files..."
        docker-compose $(docker-machine config $MACHINE_NAME) up certbot
    fi
elif [[ "$1" == "deploy" ]]; then
    utils.printer "Starting nginx machine..."
    docker-compose $(docker-machine config $MACHINE_NAME) up -d nginx
    docker-compose $(docker-machine config $MACHINE_NAME) restart nginx
elif [[ "$1" == "start" ]]; then
    utils.printer "Start services"
    docker-compose $(docker-machine config $MACHINE_NAME) start nginx
elif [[ "$1" == "restart" ]]; then
    utils.printer "Restart services"
    docker-compose $(docker-machine config $MACHINE_NAME) restart nginx
elif [[ "$1" == "stop" ]]; then
    utils.printer "Stop services"
    docker-compose $(docker-machine config $MACHINE_NAME) stop nginx
elif [[ "$1" == "rm" ]]; then
    if [[ "$2" == "all" ]]; then
        utils.printer "Stop && remove nginx service"
        docker-compose $(docker-machine config $MACHINE_NAME) rm nginx
    else
        utils.printer "Stop && remove all services"
        docker-compose $(docker-machine config $MACHINE_NAME) rm $2
    fi
elif [[ "$1" == "bash" ]]; then
    utils.printer "Connect to nginx bash shell"
    docker-compose $(docker-machine config $MACHINE_NAME) exec nginx bash
elif [[ "$1" == "ps" ]]; then
    utils.printer "Show all running containers"
    docker-compose $(docker-machine config $MACHINE_NAME) ps
elif [[ "$1" == "logs" ]]; then
    utils.printer "Showing nginx logs..."
    if [[ -z "$2" ]]; then
        docker-compose $(docker-machine config $MACHINE_NAME) logs -f --tail=30 nginx
    else
        docker-compose $(docker-machine config $MACHINE_NAME) logs -f --tail=$2 nginx
    fi
elif [[ "$1" == "up" ]]; then
    # Create machine
    bash docker.sh machine.create
    # Deploying services to remote host
    bash docker.sh config $2
    # Set server configuration
    bash docker.sh deploy $2
else
    utils.printer "Usage: docker.sh [build|up|start|restart|stop|mongo|bash|logs n_last_lines|rm|ps]"
    echo -e "up --> Build && restart nginx service"
    echo -e "start --> Start nginx service"
    echo -e "restart --> Restart nginx service"
    echo -e "stop --> Stop nginx service"
    echo -e "bash --> Connect to nginx service bash shell"
    echo -e "logs n_last_lines --> Show nginx server logs; n_last_lines parameter is optional"
    echo -e "rm --> Stop && remove nginx service"
    echo -e "rm all --> Stop && remove all services"
    echo -e "server.config --> Set nginx configuration service"
    echo -e "deploy --> Build, config && start services"
fi
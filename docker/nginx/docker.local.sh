# Utils functions
. utils.sh

# Create envs vars if don't exist
ENV_FILES=("docker-compose.yaml" ".env" "nginx/site.template" "nginx/site.template.ssl")
utils.check_envs_files "${ENV_FILES[@]}"
utils.get_host_ip

# Load environment vars, to use from console, run follow command: 
utils.load_environment 

# Menu options
if [[ "$1" == "config" ]]; then
    utils.printer "Set nginx configuration..."
    mkdir -p /opt/nginx/config/
    if [[ "$2" == "secure" ]]; then
        cp nginx/site.template.ssl /opt/nginx/config/default.conf
    else
        cp nginx/site.template /opt/nginx/config/default.conf
    fi
    utils.printer "Creating logs files..."
    mkdir -p /opt/nginx/logs/
    touch /opt/nginx/logs/site.access
    touch /opt/nginx/logs/site.error
    if [[ "$2" == "secure" ]]; then
        utils.printer "Stopping nginx machine if it's running..."
        docker-compose stop nginx
        utils.printer "Creating letsencrypt certifications files..."
        docker-compose up certbot
    fi
elif [[ "$1" == "deploy" ]]; then
    utils.printer "Starting nginx machine..."
    docker-compose up -d nginx
    docker-compose restart nginx
elif [[ "$1" == "logs" ]]; then
    utils.printer "Showing nginx logs..."
    if [[ -z "$2" ]]; then
        docker-compose logs -f --tail=30 nginx
    else
        docker-compose logs -f --tail=$2 nginx
    fi
elif [[ "$1" == "rm" ]]; then
    if [[ "$2" == "all" ]]; then
        utils.printer "Stop && remove nginx service"
        docker-compose rm nginx
    else
        utils.printer "Stop && remove all services"
        docker-compose rm $2
    fi
elif [[ "$1" == "bash" ]]; then
    utils.printer "Connect to nginx bash shell"
    docker-compose exec nginx bash
elif [[ "$1" == "ps" ]]; then
    utils.printer "Show all running containers"
    docker-compose ps
elif [[ "$1" == "start" ]]; then
    utils.printer "Start services"
    docker-compose start nginx
elif [[ "$1" == "restart" ]]; then
    utils.printer "Restart services"
    docker-compose restart nginx
elif [[ "$1" == "stop" ]]; then
    utils.printer "Stop services"
    docker-compose stop nginx
elif [[ "$1" == "up" ]]; then
    # Set initial configuration in server for nginx
    bash docker.local.sh config
    # Deploying services to remote machine server
    bash docker.local.sh deploy
else
    utils.printer "Usage: docker.local.sh [build|up|start|restart|stop|mongo|bash|logs n_last_lines|rm|ps]"
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
docker-compose -f host1-c2.yaml down -v
docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)

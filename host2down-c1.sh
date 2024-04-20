docker-compose -f host2-c1.yaml down -v
docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)

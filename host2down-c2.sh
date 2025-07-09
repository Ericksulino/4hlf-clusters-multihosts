docker-compose -f host2-c2.yaml down -v
docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)

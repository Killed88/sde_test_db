#!/bin/bash
#скачиваем образ
docker pull postgres;
#запускаем контейнер с атрибутами и volume
docker run -d --name p_task -e POSTGRES_PASSWORD=@sde_password012 -e POSTGRES_USER=test_sde -e POSTGRES_DB=demo -p 5432:5432 -v "C:\Users\Elyakhin\Desktop\study\sde_test_db\sql\init_db":/var/lib/pgsql/data postgres;
#пождем
sleep 5;
#запускаем скрипт из контейнера, создаем базу
docker exec p_task psql -U test_sde -d demo -f //var/lib/pgsql/data/demo.sql;



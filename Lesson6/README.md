# Домашнее задание "Размещаем свой RPM в своем репозитории"

## Описание/Пошаговая инструкция выполнения домашнего задания:

* создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями);
* создать свой репо и разместить там свой RPM;
* реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо.
* реализовать дополнительно пакет через docker

Методичка Управления пакетами. Дистрибьюция софта. Размещаем свой RPM в своем репозитории
https://drive.google.com/file/d/1v6dwg8TTabxQNMQadhqVBxetT8gYCsxa/view?usp=sharing

## Запуск
```
vagrant up
```
или с отладкой
```
vagrant up --debug &> vagrant.log
```

## Проверка 
Выполнить на хосте:
http://localhost:8080/repo/

Или в guest:
```
vagrant ssh
curl -a http://localhost/repo/
```

Должен быть вывод на подобие:
```
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          15-Jan-2023 16:32                   -
<a href="nginx-1.22.1-1.el8.ngx.x86_64.rpm">nginx-1.22.1-1.el8.ngx.x86_64.rpm</a>                  15-Jan-2023 16:32             2257608
<a href="percona-orchestrator-3.2.6-2.el8.x86_64.rpm">percona-orchestrator-3.2.6-2.el8.x86_64.rpm</a>        16-Feb-2022 15:57             5222976
</pre><hr></body>
</html>
```

## Файлы:

1. Vagrantfile - конфигурация виртуальной машины
2. env_preparation.sh - скрипт установки необходимых пакетов для сборки rpm пакета
3. rpm_builder.sh - скрипт сборки rpm пакета и установки репозитория


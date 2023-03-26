# Сценарии iptables 

## Описание/Пошаговая инструкция выполнения домашнего задания:

Что нужно сделать?

1. Реализовать knocking port
   * centralRouter может попасть на ssh inetrRouter через knock скрипт пример в материалах.
2. Добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
3. Запустить nginx на centralServer.
4. Пробросить 80й порт на inetRouter2 8080.
5. Дефолт в инет оставить через inetRouter.

Формат сдачи ДЗ - vagrant + ansible

**Задание со \* **: реализовать проход на 80й порт без маскарадинга

## Настройка окружения

1. За основу всят стедн из ДЗ №18:
https://github.com/vlyulin/otus-linux/tree/master/Lesson18

2. Оставлены следующие сервера

<table>
  <thead>
    <tr>
      <th>Server</th>
      <th>IP</th>
      <th>Net</th>
      <th>OS</th>
    </tr>
  </thead>
  <tbody>
    <!-- inetRouter -->
    <tr>
      <td rowspan=2>inetRouter</td>
      <td>192.168.255.1/30</td>
      <td>router-net</td>
      <td rowspan=2>Centos 7</td>
    </tr>
    <tr>
      <td>192.168.56.10/24</td>
      <td>for ansible</td>      
    </tr>
    <!-- centralRouter -->
    <tr>
      <td rowspan=4>centralRouter</td>
      <td>192.168.255.2/30</td>
      <td>router-net</td>
      <td rowspan=4>Centos 7</td>
    </tr>
    <tr>
      <td>192.168.0.1/28</td>
      <td>dir-net</td>      
    </tr>
    <tr>
      <td>192.168.0.33/28</td>
      <td>hw-net</td>      
    </tr> 
    <tr>
      <td>192.168.56.11/24</td>
      <td>for ansible</td>      
    </tr> 
    <!-- centralServer -->
    <tr>
      <td rowspan=2>inetRouter</td>
      <td>192.168.0.1/28</td>
      <td>dir-net</td>
      <td rowspan=2>Centos 7</td>
    </tr>
    <tr>
      <td>192.168.56.12/24</td>
      <td>for ansible</td>      
    </tr>
    <!-- inetRouter2 -->
    <tr>
      <td rowspan=2>inetRouter2</td>
      <td>192.168.0.34/28</td>
      <td>dir-net</td>
      <td rowspan=2>Centos 7</td>
    </tr>
    <tr>
      <td>192.168.56.13/24</td>
      <td>for ansible</td>      
    </tr>
  </tbody>
</table>


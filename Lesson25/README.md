# Домашнее задание "LDAP"

## Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку:
https://docs.google.com/document/d/1HoZBcvitZ4A9t-y6sbLEbzKmf4CWvb39/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true

### Цель домашнего задания


### Описание домашнего задания

Что нужно сделать?

Установить FreeIPA;
1. Написать Ansible playbook для конфигурации клиента;
2. Настроить аутентификацию по SSH-ключам\*
3. Firewall должен быть включен на сервере и на клиенте\*
    
Формат сдачи ДЗ - vagrant + ansible

## Запуск

```
vagrant up
```

## Решение

Проверка kinit на на сервере ipa.otus.lan:

![kinit](imgs/kinit.png)

Web-интерфейс FreeIPA-сервера http://ipa.otus.lan

![centos-identity-management](imgs/centos-identity-management.png)

Активные пользователи:

![cim-active-users](imgs/cim-active-users.png)

Добавление пользователя otus-user на ipa.otus.lan
```
ipa user-add otus-user --first=Otus --last=User --password
```

![add-user](imgs/add-user.png)

Подключение На хосте client1
![kinit-client1.png](imgs/kinit-client1.png)

Подключение На хосте client2
![kinit-client2.png](imgs/kinit-client2.png)

Созданный пользователь otus-user в web-интерфейсе ipa:

![otus-user-in-ipa1](imgs/otus-user-in-ipa1.png)

![otus-user-in-ipa](imgs/otus-user-in-ipa.png)


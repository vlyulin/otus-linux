#!/bin/sh
while IFS=":" read -r name pass uid guid comment home shell
do
echo $name $uid $home $shell
done < /etc/passwd


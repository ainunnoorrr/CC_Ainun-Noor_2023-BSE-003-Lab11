#!/bin/bash
dnf -y update
dnf -y install nginx
systemctl enable --now nginx
echo "<h1>Lab 11 nginx is working</h1>" > /usr/share/nginx/html/index.html

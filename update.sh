#!/bin/bash
 git config --global user.name "JiYou"
 git config --global user.email "jiyou09@gmail.com"
 git remote rm origin
 git remote add origin git@github.com:JiYou/book.git
 git add .
 git commit -asm "Update"
 git push origin

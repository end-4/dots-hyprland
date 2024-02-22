#!/bin/sh

getopen(){
  ans=$(eww windows | grep -e "$1")
  if [ "${ans:0:1}" == "*" ]; then
    echo 1
  else 
    echo 0
  fi
}

getopen $1
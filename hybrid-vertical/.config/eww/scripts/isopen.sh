#!/bin/sh

getopen(){
  ans=$(eww windows | grep -e "$1")
  if [ "${ans:0:1}" == "*" ]; then
    echo "true"
  else 
    echo "false"
  fi
}

getopen $1
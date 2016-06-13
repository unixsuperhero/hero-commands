#!/bin/bash

cd current
cur='../current'
src='../src'

for a in **/*
do
  echo
  if test -d "$a"; then
    if test -e "${src}/${a}"; then
      printf "EXISTS: %s/%s\n" "$src" "$a"
    else
      printf "DOES NOT EXIST: %s/%s\n" "$src" "$a"

      if test -e "${cur}/${a}"; then
        echo "VERSION FOR current/ EXISTS"
        printf "Deleting %s/%s\n" "$cur" "$a"
        rm -rfv "${cur}/${a}"
      else
        echo "VERSION FOR current/ **DOES NOT** EXIST"
      fi

      if test -e "${HOME}/${a}"; then
        echo "VERSION FOR ${HOME}/ EXISTS"
        printf "Deleting %s/%s\n" "$HOME" "$a"
        rm -rfv "${HOME}/${a}"
      else
        echo "VERSION FOR ${HOME}/ **DOES NOT** EXIST"
      fi
    fi
  else
    if test -f "$a"; then
      if test -e "${src}/${a}.erb"; then
        printf "EXISTS: %s/%s.erb\n" "$src" "$a"
      else
        printf "DOES NOT EXIST: %s/%s.erb\n" "$src" "$a"

        if test -e "${cur}/${a}"; then
          echo "VERSION FOR current/ EXISTS"
          printf "Deleting %s/%s\n" "$cur" "$a"
          rm -v "${cur}/${a}"
        else
          echo "VERSION FOR current/ **DOES NOT** EXIST"
        fi

        if test -e "${HOME}/${a}"; then
          echo "VERSION FOR ${HOME}/ EXISTS"
          printf "Deleting %s/%s\n" "$HOME" "$a"
          rm -v "${HOME}/${a}"
        else
          echo "VERSION FOR ${HOME}/ **DOES NOT** EXIST"
        fi
      fi
    fi
  fi
  echo
done



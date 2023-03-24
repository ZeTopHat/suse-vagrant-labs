#!/bin/bash

# Copy to 
_sumalabs() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help mgr-sync lab1 lab2 lab3"

    case "${prev}" in
        sumalabs)
            opts="--help mgr-sync registration patching"
            ;;
        mgr-sync)
            opts="--lab1 --lab2 --lab3 --lab4 --reset --full"
            ;;
        registration)
            opts="--lab1 --lab2 --lab3 --lab4" # --reset --full
            ;;
        patching)
            opts="--lab1 --lab2 --lab3 --lab4" # --reset --full
            ;;
        *)
            opts=""
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _sumalabs sumalabs
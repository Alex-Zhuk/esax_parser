#!/bin/sh

start() {
    erl -pz $PWD/ebin/ -pz $PWD/deps/*/ebin/ -sname dev1 -s esax_parser -config sys
}

start

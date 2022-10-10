#!/bin/bash

patch --strip=1 -ruN -d $1 < $2

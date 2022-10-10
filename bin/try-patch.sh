#!/bin/bash

patch --dry-run --strip=1 -ruN -d $1 < $2

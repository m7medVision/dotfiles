#!/bin/sh
sensors | grep -E "(CPU)" | awk '{print $2}'   

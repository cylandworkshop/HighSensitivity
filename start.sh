#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

trap ctrl_c INT

function ctrl_c() {
    echo "go away by default"
    sudo bash -c "echo 0 >/sys/class/leds/led0/brightness"
    exit 0
}

list_descendants () {
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children; do
    list_descendants "$pid"
  done

  echo "$children"
}

sudo bash -c "echo none >/sys/class/leds/led0/trigger"
sudo bash -c "echo 1 >/sys/class/leds/led0/brightness"

raspi-gpio set 23 op
echo 23 >/sys/class/gpio/export

echo "Start script by default: Danita"

PRINT_DIR=/data/danita/print

date

LONG_REPEATS=1
MEDIUM_REPEATS=5
SHORT_REPEATS=5

AFTER_PRINT_TIMES=3 # x10s

cd $PRINT_DIR
(
    for i in $(seq $LONG_REPEATS); do find long -type f; done
    for i in $(seq $MEDIUM_REPEATS); do find medium -type f; done
    for i in $(seq $SHORT_REPEATS); do find short -type f; done
) | shuf | while read file; do
    echo
    echo "Printing $file"
    width=$(identify -format "%w" $file)
    height=$(identify -format "%h" $file)
    length=$(expr 600 \* $height / $width + 50)
    echo "$width x $height, $length"
    lp -d designjet500 $file -o media="Custom.600x${length}mm"

    sleep 8s

    echo "1" > /sys/class/gpio/gpio23/value

    while [[ -z $(lpstat -p designjet500 | grep idle) ]]; do
      sleep 1s
    done
    echo "print done"
    echo

    sleep 5s
    
    echo "0" > /sys/class/gpio/gpio23/value

    for i in $(seq $AFTER_PRINT_TIMES); do
        sleep "$(expr $RANDOM / 5000 + 5)s"
        echo "1" > /sys/class/gpio/gpio23/value
        sleep "$(expr $RANDOM / 10000 + 1)s"
        echo "0" > /sys/class/gpio/gpio23/value
    done
done

echo "end"
date

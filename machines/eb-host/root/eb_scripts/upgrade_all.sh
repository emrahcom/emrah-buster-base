#!/bin/bash

echo
echo "<<< HOST >>>"
echo
/root/eb_scripts/upgrade_debian.sh

echo
echo "<<< CONTAINERS >>>"
echo
/root/eb_scripts/upgrade_container.sh

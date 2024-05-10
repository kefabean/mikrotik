#!/bin/bash

# Script to create backup of Mikrotik config with datestamp and copy to
# local workstation. Prompts for comment to describe latest change.

DATE=$(date +"%Y%m%d-%H%M")
read -p "Enter short comment using letters and hyphens only: " COMMENT
FILE="mikrotik-${DATE}-${COMMENT}.rsc"
ssh admin@router.lan "export file=${FILE}"
scp admin@router.lan:~/$FILE .

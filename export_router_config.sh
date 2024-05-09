DATE=$(date +"%Y%m%d-%H%M")
read -p "Enter short comment using letters and hyphens only: " COMMENT
FILE="mikrotik-${DATE}-${COMMENT}.rsc"
ssh admin@router.lan "export file=${FILE}"
scp admin@router.lan:~/$FILE .

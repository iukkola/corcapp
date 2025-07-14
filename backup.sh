#!/bin/bash
# CORC App Backup Script
# Luo päivätyn backupin projektista

BACKUP_DIR="$HOME/CORC_backups"
PROJECT_DIR="$HOME/hiilikrediitti-appi"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="corc_backup_${TIMESTAMP}"

# Luo backup-kansio jos ei ole
mkdir -p "$BACKUP_DIR"

echo "🔄 Luodaan backup..."

# Tapa 1: ZIP-arkisto (nopea)
cd "$PROJECT_DIR/.."
zip -r "$BACKUP_DIR/${BACKUP_NAME}.zip" hiilikrediitti-appi \
    -x "*/venv/*" \
    -x "*/__pycache__/*" \
    -x "*/node_modules/*" \
    -x "*/.dart_tool/*" \
    -x "*/build/*" \
    -x "*.log"

# Tapa 2: Kopioi myös palvelimen tietokanta (valinnainen)
echo "📥 Haluatko kopioida myös tuotannon tietokannan? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
    scp root@co2:/root/hiilikrediitti-appi/backend/users.db \
        "$BACKUP_DIR/${BACKUP_NAME}_production_users.db"
fi

echo "✅ Backup valmis!"
echo "📍 Sijainti: $BACKUP_DIR/${BACKUP_NAME}.zip"
echo ""
echo "📊 Backup-tilastot:"
ls -lh "$BACKUP_DIR/${BACKUP_NAME}"*
echo ""
echo "💡 Vinkki: Kopioi backup myös pilveen (iCloud/Dropbox/Google Drive)"
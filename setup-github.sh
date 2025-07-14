#!/bin/bash
# GitHub setup helper script

echo "🔗 GitHub-repositorion lisääminen CORC-projektille"
echo ""
echo "1. Luo ensin PRIVATE repository GitHubissa:"
echo "   https://github.com/new"
echo ""
echo "2. Anna repositorion nimi (esim. corc-carbon-credit-app)"
echo "3. Valitse 'Private' repository"
echo "4. ÄLÄ valitse 'Initialize with README'"
echo ""
echo "Kun olet luonut repon, anna sen URL (esim. https://github.com/käyttäjänimi/repo-nimi):"
read -r REPO_URL

# Varmista että ollaan oikeassa kansiossa
cd ~/hiilikrediitti-appi || exit

# Lisää remote
git remote add origin "$REPO_URL"

echo ""
echo "✅ Remote lisätty! Tarkistetaan tilanne..."
git remote -v

echo ""
echo "📤 Pushataan koodi GitHubiin..."
git push -u origin main

echo ""
echo "🎉 Valmis! Projektisi on nyt GitHubissa."
echo ""
echo "🔐 Muista:"
echo "- Repository on PRIVATE"
echo "- .gitignore estää sensitiivisten tiedostojen lähetyksen"
echo "- Voit jakaa repon tiimillesi GitHub Settings -> Manage access"
#!/bin/zsh
# youtube-mp3.sh

# Kolory do outputu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funkcja sprawdzająca yt-dlp
check_ytdlp() {
    if command -v yt-dlp &> /dev/null; then
        echo -e "${GREEN}✅ yt-dlp jest zainstalowane${NC}"
        CURRENT_VERSION=$(yt-dlp --version 2>/dev/null | head -n1)
        echo "📌 Wersja: $CURRENT_VERSION"
        return 0
    else
        echo -e "${RED}❌ yt-dlp nie jest zainstalowane${NC}"
        return 1
    fi
}

# Funkcja instalująca yt-dlp
install_ytdlp() {
    echo -e "${YELLOW}📦 Instalacja yt-dlp...${NC}"
    echo ""
    echo "Wybierz metodę instalacji:"
    echo "1) Binarka (zalecane - najszybsze)"
    echo "2) pipx (zarządzanie wersją)"
    echo "3) Docker (zawsze aktualne)"
    echo "4) Anuluj"
    echo ""
    read -r "choice?Wybór [1-4]: "

    case $choice in
        1)
            echo -e "${YELLOW}🔧 Instalacja przez wget...${NC}"
            sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
                -O /usr/local/bin/yt-dlp
            sudo chmod a+rx /usr/local/bin/yt-dlp

            if command -v yt-dlp &> /dev/null; then
                echo -e "${GREEN}✅ yt-dlp zainstalowane pomyślnie!${NC}"
                yt-dlp --version
            else
                echo -e "${RED}❌ Instalacja nie powiodła się${NC}"
                exit 1
            fi
            ;;
        2)
            echo -e "${YELLOW}🔧 Instalacja przez pipx...${NC}"

            # Sprawdź czy pipx jest zainstalowany
            if ! command -v pipx &> /dev/null; then
                echo "📦 Instaluję pipx..."
                sudo apt update && sudo apt install -y pipx
                pipx ensurepath
                export PATH="$HOME/.local/bin:$PATH"
            fi

            pipx install yt-dlp

            if command -v yt-dlp &> /dev/null; then
                echo -e "${GREEN}✅ yt-dlp zainstalowane pomyślnie!${NC}"
                yt-dlp --version
            else
                echo -e "${RED}❌ Instalacja nie powiodła się${NC}"
                echo "Dodaj do ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
                exit 1
            fi
            ;;
        3)
            echo -e "${YELLOW}🐳 Konfiguracja aliasu Docker...${NC}"

            # Sprawdź czy Docker jest zainstalowany
            if ! command -v docker &> /dev/null; then
                echo -e "${RED}❌ Docker nie jest zainstalowany${NC}"
                echo "Zainstaluj Docker: https://docs.docker.com/engine/install/"
                exit 1
            fi

            # Dodaj alias do .zshrc
            ALIAS_LINE='alias yt-dlp="docker run --rm -v \$(pwd):/downloads jauderho/yt-dlp:latest"'

            if ! grep -q "alias yt-dlp=" ~/.zshrc; then
                echo "$ALIAS_LINE" >> ~/.zshrc
                echo -e "${GREEN}✅ Alias dodany do ~/.zshrc${NC}"
                echo "Uruchom: source ~/.zshrc"
            else
                echo -e "${YELLOW}⚠️  Alias już istnieje w ~/.zshrc${NC}"
            fi

            eval "$ALIAS_LINE"
            echo -e "${GREEN}✅ Alias Docker skonfigurowany!${NC}"
            ;;
        4)
            echo -e "${YELLOW}❌ Anulowano${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Nieprawidłowy wybór${NC}"
            exit 1
            ;;
    esac
}

# Funkcja sprawdzająca Deno (opcjonalnie)
check_deno() {
    if command -v deno &> /dev/null; then
        echo -e "${GREEN}✅ Deno jest zainstalowane${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Deno nie jest zainstalowane (opcjonalne, ale zalecane)${NC}"
        read -r "install_deno?Czy chcesz zainstalować Deno? [y/N]: "

        if [[ "$install_deno" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🔧 Instalacja Deno...${NC}"
            curl -fsSL https://deno.land/install.sh | sh

            # Dodaj do PATH
            export DENO_INSTALL="$HOME/.deno"
            export PATH="$DENO_INSTALL/bin:$PATH"

            if ! grep -q 'DENO_INSTALL' ~/.zshrc; then
                echo 'export DENO_INSTALL="$HOME/.deno"' >> ~/.zshrc
                echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ~/.zshrc
            fi

            if command -v deno &> /dev/null; then
                echo -e "${GREEN}✅ Deno zainstalowane pomyślnie!${NC}"
                deno --version
            fi
        fi
        return 1
    fi
}

# GŁÓWNA CZĘŚĆ SKRYPTU
echo "🎵 YouTube MP3 Downloader"
echo "=========================="
echo ""

# Sprawdź yt-dlp
if ! check_ytdlp; then
    install_ytdlp
fi

echo ""

# Sprawdź Deno (opcjonalnie)
check_deno

echo ""
echo "=========================="
echo ""

# Plik z linkami
LINKS_FILE="${1:-links.txt}"

# Sprawdź czy plik istnieje
if [[ ! -f "$LINKS_FILE" ]]; then
    echo -e "${RED}❌ Plik $LINKS_FILE nie istnieje!${NC}"
    echo ""
    echo "Utwórz plik z linkami:"
    echo "  cat > links.txt << 'EOF'"
    echo "  https://www.youtube.com/watch?v=..."
    echo "  https://www.youtube.com/watch?v=..."
    echo "  EOF"
    echo ""
    echo "Lub podaj linki jako argumenty:"
    echo "  $0 link1 link2 link3"
    exit 1
fi

# Zlicz linki
TOTAL=$(grep -v '^#' "$LINKS_FILE" | grep -v '^[[:space:]]*$' | wc -l)
CURRENT=0

echo "📥 Pobieranie $TOTAL plików z $LINKS_FILE"
echo ""

# Pobierz każdy link
while IFS= read -r url; do
    # Pomiń puste linie i komentarze
    [[ -z "$url" || "$url" =~ ^# ]] && continue

    ((CURRENT++))
    echo -e "${YELLOW}[$CURRENT/$TOTAL]${NC} 📥 Pobieranie: $url"

    yt-dlp \
        --extractor-args "youtube:player_client=android" \
        -x --audio-format mp3 \
        --embed-thumbnail \
        --add-metadata \
        "$url"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Pobrano pomyślnie${NC}"
    else
        echo -e "${RED}❌ Błąd pobierania: $url${NC}"
    fi
    echo "---"
done < "$LINKS_FILE"

echo ""
echo -e "${GREEN}🎉 Zakończono pobieranie!${NC}"

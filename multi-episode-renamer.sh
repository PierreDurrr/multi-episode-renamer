#!/bin/bash

# Script de Renommage d'Episodes TV
# Version Bash améliorée

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage de titre
print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "   $1"
    echo -e "==========================================${NC}"
    echo
}

# Fonction d'affichage d'erreur
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction d'affichage de succès
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction d'affichage d'avertissement
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Fonction de validation des entrées numériques
validate_number() {
    local input="$1"
    local min="$2"
    local max="$3"
    
    # Vérifier que c'est un nombre
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Vérifier la plage avec arithmétique
    if (( input < min || input > max )); then
        return 1
    fi
    
    return 0
}

# Fonction de détection du pattern S##E##
detect_series_info() {
    local filename="$1"
    local detected_series=""
    local detected_season=""
    local detected_suffix=""
    
    # Pattern pour S##E## (ex: S01E01)
    if [[ "$filename" =~ ^(.+)[._[:space:]]S([0-9]{2})E([0-9]{2})(.*)$ ]]; then
        detected_series="${BASH_REMATCH[1]}"
        detected_season="${BASH_REMATCH[2]}"
        detected_suffix="${BASH_REMATCH[4]}"
        
        # Nettoyer le nom de série
        detected_series="${detected_series//_/.}"
        detected_series="${detected_series// /.}"
        
        # Ajouter le point au début du suffixe si nécessaire
        if [[ ! "$detected_suffix" =~ ^\. ]] && [ -n "$detected_suffix" ]; then
            detected_suffix=".$detected_suffix"
        fi
        
        echo "$detected_series|$detected_season|$detected_suffix"
        return 0
    fi
    
    # Pattern alternatif avec tirets (ex: Serie-S01E01)
    if [[ "$filename" =~ ^(.+)-S([0-9]{2})E([0-9]{2})(.*)$ ]]; then
        detected_series="${BASH_REMATCH[1]}"
        detected_season="${BASH_REMATCH[2]}"
        detected_suffix="${BASH_REMATCH[4]}"
        
        detected_series="${detected_series//-/.}"
        
        if [[ ! "$detected_suffix" =~ ^\. ]] && [ -n "$detected_suffix" ]; then
            detected_suffix=".$detected_suffix"
        fi
        
        echo "$detected_series|$detected_season|$detected_suffix"
        return 0
    fi
    
    # Aucun pattern trouvé
    return 1
}

# Fonction pour construire la chaîne d'épisodes
build_episode_string() {
    local start_ep=$1
    local count=$2
    local episode_string=""
    
    for ((i=0; i<count; i++)); do
        local current_ep=$((start_ep + i))
        printf -v ep_formatted "E%02d" "$current_ep"
        episode_string="${episode_string}${ep_formatted}"
    done
    
    echo "$episode_string"
}

# Fonction pour construire le nouveau nom de fichier
build_new_filename() {
    local series="$1"
    local season="$2"
    local episode_string="$3"
    local suffix="$4"
    local has_final="$5"
    
    # Nettoyer le suffixe de tout tag FiNAL existant
    local clean_suffix="${suffix}"
    clean_suffix="${clean_suffix//.FiNAL/}"
    clean_suffix="${clean_suffix//.FINAL/}"
    clean_suffix="${clean_suffix//.final/}"
    
    if [ "$has_final" = "true" ]; then
        echo "${series}.S${season}${episode_string}.FiNAL${clean_suffix}"
    else
        echo "${series}.S${season}${episode_string}${clean_suffix}"
    fi
}

# Début du script principal
clear
print_header "Script de Renommage d'Episodes TV"

# Vérifier qu'il y a des fichiers .mkv
shopt -s nullglob
mkv_files=(*.mkv)
shopt -u nullglob

if [ ${#mkv_files[@]} -eq 0 ]; then
    print_error "Aucun fichier .mkv trouvé dans le répertoire actuel."
    exit 1
fi

echo "Nombre de fichiers .mkv trouvés : ${#mkv_files[@]}"
echo

# Détection automatique depuis le premier fichier
first_file="${mkv_files[0]}"
echo "Premier fichier détecté : $first_file"
echo

detected_info=$(detect_series_info "$first_file")

if [ $? -eq 0 ]; then
    IFS='|' read -r detected_series detected_season detected_suffix <<< "$detected_info"
else
    print_warning "Pattern S##E## non détecté, utilisation de valeurs par défaut"
    detected_series="Serie.Inconnue"
    detected_season="01"
    detected_suffix=".1080p.WEB.x264-RELEASE.mkv"
fi

# Valeurs par défaut si vides
[ -z "$detected_series" ] && detected_series="Serie.Inconnue"
[ -z "$detected_season" ] && detected_season="01"
[ -z "$detected_suffix" ] && detected_suffix=".1080p.WEB.x264-RELEASE.mkv"

echo "Série détectée : \"$detected_series\""
echo "Saison détectée : S$detected_season"
echo "Suffixe qualité détecté : \"$detected_suffix\""
echo

read -p "Confirmer ces détections ? (O/n) : " confirm_detect
if [[ "$confirm_detect" =~ ^[nN]$ ]]; then
    echo
    echo "Modification des paramètres :"
    read -p "Nom de la série : " detected_series
    read -p "Numéro de saison (ex: 02) : " detected_season
    read -p "Suffixe qualité/release (ex: .1080p.WEB.x264-RELEASE.mkv) : " detected_suffix
fi

echo
print_header "Configuration des épisodes par groupe"
echo "Combien d'épisodes par fichier ?"
echo "  2 - Deux épisodes (E01E02)"
echo "  3 - Trois épisodes (E01E02E03)"
echo "  4 - Quatre épisodes (E01E02E03E04)"
echo "  5 - Cinq épisodes (E01E02E03E04E05)"
echo "  6 - Six épisodes (E01E02E03E04E05E06)"
echo

episodes_per_group=""
while true; do
    read -p "Votre choix (2-6) : " episodes_per_group
    if validate_number "$episodes_per_group" 2 6; then
        break
    else
        print_error "Veuillez entrer un nombre entre 2 et 6"
    fi
done

echo
print_header "Récapitulatif"
echo "Série : $detected_series"
echo "Saison : S$detected_season"
echo "Suffixe : $detected_suffix"
echo "Épisodes par groupe : $episodes_per_group"
echo

read -p "Continuer avec ces paramètres ? (O/n) : " confirm_params
if [[ "$confirm_params" =~ ^[nN]$ ]]; then
    echo "Opération annulée."
    exit 0
fi

echo
print_header "Aperçu des renommages"

# Préparer le tableau des renommages
declare -a old_names
declare -a new_names

i=0
for old_file in "${mkv_files[@]}"; do
    start_ep=$((1 + i * episodes_per_group))
    episode_string=$(build_episode_string "$start_ep" "$episodes_per_group")
    
    # Détecter si le fichier contient "final"
    has_final="false"
    if [[ "$old_file" =~ [Ff][Ii][Nn][Aa][Ll] ]]; then
        has_final="true"
    fi
    if [[ "$detected_suffix" =~ [Ff][Ii][Nn][Aa][Ll] ]]; then
        has_final="true"
    fi
    
    new_name=$(build_new_filename "$detected_series" "$detected_season" "$episode_string" "$detected_suffix" "$has_final")
    
    old_names+=("$old_file")
    new_names+=("$new_name")
    
    echo "$i. \"$old_file\""
    echo "   → \"$new_name\""
    
    if [ -e "$new_name" ]; then
        print_warning "Le fichier destination existe déjà !"
    fi
    echo
    
    i=$((i + 1))
done

print_header "Confirmation finale"
echo "Vous allez renommer ${#mkv_files[@]} fichier(s)."
echo

read -p "Procéder au renommage ? (O/n) : " final_confirm
if [[ "$final_confirm" =~ ^[nN]$ ]]; then
    echo "Opération annulée."
    exit 0
fi

echo
print_header "Renommage en cours..."

# Effectuer les renommages
success_count=0
error_count=0

for ((i=0; i<${#old_names[@]}; i++)); do
    old_name="${old_names[$i]}"
    new_name="${new_names[$i]}"
    
    echo "Traitement du fichier $i : \"$old_name\""
    
    if [ -e "$new_name" ] && [ "$old_name" != "$new_name" ]; then
        print_warning "Le fichier \"$new_name\" existe déjà !"
        read -p "Remplacer ? (O/n) : " overwrite
        if [[ "$overwrite" =~ ^[nN]$ ]]; then
            print_error "Fichier ignoré."
            error_count=$((error_count + 1))
            echo
            continue
        fi
        rm -f "$new_name"
    fi
    
    if [ "$old_name" = "$new_name" ]; then
        print_warning "Nom identique, fichier ignoré"
        success_count=$((success_count + 1))
    elif mv "$old_name" "$new_name" 2>/dev/null; then
        print_success "Renommage réussi"
        success_count=$((success_count + 1))
    else
        print_error "Erreur lors du renommage"
        error_count=$((error_count + 1))
    fi
    echo
done

print_header "Renommage terminé !"
echo "Fichiers renommés avec succès : $success_count"
echo "Fichiers en erreur ou ignorés : $error_count"
echo "Total traité : $((success_count + error_count))"
echo

read -p "Appuyez sur Entrée pour terminer..."

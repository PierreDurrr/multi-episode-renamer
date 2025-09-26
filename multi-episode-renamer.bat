@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ==========================================
echo    Script de Renommage d'Episodes TV
echo ==========================================
echo.

rem Détection automatique du nom de série depuis le premier fichier
set "detectedSeries="
set "detectedSeason="
for %%F in ("*.mkv") do (
    set "firstFile=%%~nxF"
    goto :detectSeries
)

:detectSeries
if "%firstFile%"=="" (
    echo Aucun fichier .mkv trouvé dans le répertoire actuel.
    pause
    exit /b 1
)

echo Premier fichier détecté : %firstFile%
echo.

rem Amélioration de la détection avec expressions régulières simulées
set "detectedSeries="
set "detectedSeason="
set "detectedSuffix="

rem Méthode améliorée : chercher le pattern S##E## dans le nom
set "tempName=!firstFile!"
set "foundPattern=0"

rem Parcourir le nom pour trouver le pattern S##E##
for /l %%i in (1,1,50) do (
    if !foundPattern! == 0 (
        set "testChar=!tempName:~%%i,1!"
        if "!testChar!" == "S" (
            rem Vérifier si on a S##E## après cette position
            set "seasonPart=!tempName:~%%i,6!"
            set "seasonNum=!seasonPart:~1,2!"
            set "ePart=!seasonPart:~3,1!"
            set "episodeNum=!seasonPart:~4,2!"
            
            rem Vérifier que c'est bien S##E##
            if "!ePart!" == "E" (
                rem On a trouvé le pattern, extraire les parties
                set "detectedSeries=!tempName:~0,%%i!"
                set "detectedSeason=!seasonNum!"
                
                rem Calculer position après S##E##
                set /a suffixStart=%%i + 6
                call set "detectedSuffix=%%tempName:~!suffixStart!%%"
                
                rem Garder le point final du nom de série s'il existe, sinon ne pas en ajouter
                rem (on respecte la structure originale du fichier)
                
                rem Ajouter le point au début du suffixe s'il n'y est pas
                if not "!detectedSuffix:~0,1!" == "." (
                    set "detectedSuffix=.!detectedSuffix!"
                )
                
                set "foundPattern=1"
            )
        )
    )
)

rem Si on n'a pas trouvé de pattern S##E##, essayer une approche alternative
if !foundPattern! == 0 (
    echo Pattern S##E## non trouvé, tentative d'analyse alternative...
    
    rem Chercher d'autres patterns communs comme saison/episode
    for /f "tokens=1,2,3,4,5,6,7,8,9,10 delims=." %%a in ("!firstFile!") do (
        set "part1=%%a"
        set "part2=%%b"
        set "part3=%%c"
        set "part4=%%d"
        set "part5=%%e"
        set "part6=%%f"
        set "part7=%%g"
        set "part8=%%h"
        set "part9=%%i"
        set "part10=%%j"
        
        rem Reconstruire intelligemment
        set "detectedSeries=!part1!"
        if "!part2!" neq "" if "!part2:~0,1!" neq "S" (
            set "detectedSeries=!detectedSeries! !part2!"
        )
        if "!part3!" neq "" if "!part3:~0,1!" neq "S" (
            set "detectedSeries=!detectedSeries! !part3!"
        )
        
        rem Chercher la partie saison
        if "!part2:~0,1!" == "S" set "detectedSeason=!part2:~1,2!" & goto :suffixFound
        if "!part3:~0,1!" == "S" set "detectedSeason=!part3:~1,2!" & goto :suffixFound
        if "!part4:~0,1!" == "S" set "detectedSeason=!part4:~1,2!" & goto :suffixFound
    )
    
    :suffixFound
    rem Construire le suffixe par défaut si pas trouvé
    if "!detectedSuffix!" == "" (
        set "detectedSuffix=.TRUEFRENCH.1080p.WEB-DL.H264-FTMVHD.mkv"
    )
)

rem Valeurs par défaut si tout échoue
if "!detectedSeries!" == "" set "detectedSeries=Serie Inconnue"
if "!detectedSeason!" == "" set "detectedSeason=01"
if "!detectedSuffix!" == "" set "detectedSuffix=.1080p.WEB.x264-FTMVHD.mkv"

echo Série détectée : "!detectedSeries!"
echo Saison détectée : S!detectedSeason!
echo Suffixe qualité détecté : "!detectedSuffix!"
echo.
set /p "confirmSeries=Confirmer ces détections ? (O/n) : "
if /i "!confirmSeries!"=="n" (
    echo.
    echo Modification des paramètres :
    set /p "detectedSeries=Nom de la série : "
    set /p "detectedSeason=Numéro de saison (ex: 02) : "
    set /p "detectedSuffix=Suffixe qualité/release (ex: .1080p.WEB.x264-FTMVHD.mkv) : "
)

echo.
echo ==========================================
echo Configuration des épisodes par groupe
echo ==========================================
echo Combien d'épisodes par fichier ?
echo   2 - Deux épisodes (E01E02)
echo   3 - Trois épisodes (E01E02E03)
echo   4 - Quatre épisodes (E01E02E03E04)
echo   5 - Cinq épisodes (E01E02E03E04E05)
echo   6 - Six épisodes (E01E02E03E04E05E06)
echo.
set /p "episodesPerGroup=Votre choix (2-6) : "

rem Validation du choix
if !episodesPerGroup! lss 2 set "episodesPerGroup=3"
if !episodesPerGroup! gtr 6 set "episodesPerGroup=3"

echo.
echo ==========================================
echo Récapitulatif
echo ==========================================
echo Série : !detectedSeries!
echo Saison : S!detectedSeason!
echo Suffixe : !detectedSuffix!
echo Épisodes par groupe : !episodesPerGroup!
echo.
set /p "confirm=Continuer avec ces paramètres ? (O/n) : "
if /i "!confirm!"=="n" (
    echo Opération annulée.
    pause
    exit /b 0
)

echo.
echo ==========================================
echo Aperçu des renommages
echo ==========================================

rem Compter les fichiers pour information
set "fileCount=0"
for %%F in ("*.mkv") do set /a fileCount+=1
echo Nombre de fichiers trouvés : !fileCount!
echo.

rem Première passe : afficher tous les renommages prévus
set "i=0"
echo Liste des renommages prévus :
echo.
for %%F in ("*.mkv") do (
    set "filename=%%~nxF"
    set /a startEp=1 + !i! * !episodesPerGroup!
    
    rem Construction de la chaîne des épisodes
    set "episodeString="
    for /l %%e in (0, 1, !episodesPerGroup!) do (
        if %%e lss !episodesPerGroup! (
            set /a currentEp=!startEp! + %%e
            if !currentEp! lss 10 (
                set "episodeString=!episodeString!E0!currentEp!"
            ) else (
                set "episodeString=!episodeString!E!currentEp!"
            )
        )
    )
    
    rem Vérifie si "FiNAL" est dans le suffixe détecté
    echo !detectedSuffix! | findstr /i "final" >nul
    if !errorlevel! == 0 (
        set "hasFinal=1"
        rem Créer un suffixe sans FiNAL pour les fichiers normaux
        set "cleanSuffix=!detectedSuffix!"
        set "cleanSuffix=!cleanSuffix:.FiNAL=!"
        set "cleanSuffix=!cleanSuffix:.FINAL=!"
        set "cleanSuffix=!cleanSuffix:.final=!"
    ) else (
        set "hasFinal=0"
        set "cleanSuffix=!detectedSuffix!"
    )
    
    rem Vérifie aussi si "FiNAL" est dans le nom de fichier actuel
    echo !filename! | findstr /i "final" >nul
    if !errorlevel! == 0 set "hasFinal=1"
    
    rem Construit le nouveau nom
    if !hasFinal! == 1 (
        rem S'assurer que FiNAL est dans le suffixe
        if "!detectedSuffix!"=="!cleanSuffix!" (
            rem Ajouter FiNAL si pas déjà présent
            for /f "tokens=1,* delims=." %%p in ("!cleanSuffix:~1!") do (
                set "newname=!detectedSeries!.S!detectedSeason!!episodeString!.FiNAL.%%p.%%q"
            )
        ) else (
            set "newname=!detectedSeries!.S!detectedSeason!!episodeString!!detectedSuffix!"
        )
    ) else (
        set "newname=!detectedSeries!.S!detectedSeason!!episodeString!!cleanSuffix!"
    )
    
    echo !i!. "!filename!"
    echo    → "!newname!"
    
    rem Vérifier si le fichier destination existe déjà
    if exist "!newname!" (
        echo    ⚠️  ATTENTION: Le fichier destination existe déjà !
    )
    echo.
    
    set /a i+=1
)

echo ==========================================
echo Confirmation finale
echo ==========================================
echo Vous allez renommer !fileCount! fichier(s).
echo.
set /p "finalConfirm=Procéder au renommage ? (O/n) : "
if /i "!finalConfirm!"=="n" (
    echo Opération annulée.
    pause
    exit /b 0
)

echo.
echo ==========================================
echo Renommage en cours...
echo ==========================================

rem Deuxième passe : effectuer les renommages
set "i=0"
for %%F in ("*.mkv") do (
    set "filename=%%~nxF"
    set /a startEp=1 + !i! * !episodesPerGroup!
    
    rem Construction de la chaîne des épisodes
    set "episodeString="
    for /l %%e in (0, 1, !episodesPerGroup!) do (
        if %%e lss !episodesPerGroup! (
            set /a currentEp=!startEp! + %%e
            if !currentEp! lss 10 (
                set "episodeString=!episodeString!E0!currentEp!"
            ) else (
                set "episodeString=!episodeString!E!currentEp!"
            )
        )
    )
    
    rem Vérifie si "FiNAL" est dans le suffixe détecté
    echo !detectedSuffix! | findstr /i "final" >nul
    if !errorlevel! == 0 (
        set "hasFinal=1"
        rem Créer un suffixe sans FiNAL pour les fichiers normaux
        set "cleanSuffix=!detectedSuffix!"
        set "cleanSuffix=!cleanSuffix:.FiNAL=!"
        set "cleanSuffix=!cleanSuffix:.FINAL=!"
        set "cleanSuffix=!cleanSuffix:.final=!"
    ) else (
        set "hasFinal=0"
        set "cleanSuffix=!detectedSuffix!"
    )
    
    rem Vérifie aussi si "FiNAL" est dans le nom de fichier actuel
    echo !filename! | findstr /i "final" >nul
    if !errorlevel! == 0 set "hasFinal=1"
    
    rem Construit le nouveau nom
    if !hasFinal! == 1 (
        rem S'assurer que FiNAL est dans le suffixe
        if "!detectedSuffix!"=="!cleanSuffix!" (
            rem Ajouter FiNAL si pas déjà présent
            for /f "tokens=1,* delims=." %%p in ("!cleanSuffix:~1!") do (
                set "newname=!detectedSeries!.S!detectedSeason!!episodeString!.FiNAL.%%p.%%q"
            )
        ) else (
            set "newname=!detectedSeries!.S!detectedSeason!!episodeString!!detectedSuffix!"
        )
    ) else (
        set "newname=!detectedSeries!.S!detectedSeason!!episodeString!!cleanSuffix!"
    )
    
    echo Traitement du fichier !i! : "!filename!"
    
    rem Vérifier si le fichier destination existe déjà
    if exist "!newname!" (
        echo ⚠️  Le fichier "!newname!" existe déjà !
        set /p "overwrite=Remplacer ? (O/n) : "
        if /i "!overwrite!"=="n" (
            echo ❌ Fichier ignoré.
            echo.
            goto :nextFile
        )
    )
    
    ren "!filename!" "!newname!"
    if !errorlevel! == 0 (
        echo ✅ Renommage réussi
    ) else (
        echo ❌ Erreur lors du renommage
    )
    echo.
    
    :nextFile
    set /a i+=1
)

echo ==========================================
echo Renommage terminé !
echo Nombre de fichiers traités : !i!
echo ==========================================
pause
endlocal

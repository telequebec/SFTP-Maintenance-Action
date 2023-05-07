#!/bin/sh

REMOTE_PATH="$1"

# Liste des fichiers
find "$REMOTE_PATH" -type f

# Liste des dossiers
find "$REMOTE_PATH" -type d

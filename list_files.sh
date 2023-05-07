#!/bin/sh

REMOTE_PATH="$1"

# Liste des fichiers
ls -la "$REMOTE_PATH" | grep '^-' | awk '{print $NF}'

# Liste des dossiers
ls -la "$REMOTE_PATH" | grep '^d' | awk '{print $NF}'
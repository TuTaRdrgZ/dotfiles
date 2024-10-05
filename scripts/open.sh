#!/bin/bash

open_directory() {
	if command -v nautilus &> /dev/null; then
		nautilus "$1" >/dev/null 2>&1 &
	elif command -v thunar &> /dev/null; then
		thunar "$1" >/dev/null 2>&1 &
	elif command -v nemo &> /dev/null; then
		nemo "$1" >/dev/null 2>&1 &
	elif command -v xdg-open &> /dev/null; then
		xdg-open "$1" >/dev/null 2>&1 &
	elif command -v gvfs-open &> /dev/null; then
		gvfs-open "$1" >/dev/null 2>&1 &
	elif command -v kde-open &> /dev/null; then
		kde-open "$1" >/dev/null 2>&1 &
	else
		echo "No se encontró un gestor de archivos compatible."
	fi
}

# Función para abrir un archivo con el editor de texto adecuado
open_file() {
	if command -v nvim &> /dev/null; then
		nvim "$1" 
	elif command -v vim &> /dev/null; then
		vim "$1" 
	elif command -v nano &> /dev/null; then
		nano "$1" 
	else
		xdg-open "$1" >/dev/null 2>&1 
	fi
}

if [ $# -eq 0 ]; then
	# Si no se proporcionan argumentos, abre el directorio actual en Thunar
	thunar .
else
	for arg in "$@"; do
		if [ -d "$arg" ]; then
			# Si el argumento es un directorio, ábrelo en Thunar
			open_directory "$arg"
		elif [ -f "$arg" ]; then
			# Si el argumento es un archivo, determina el tipo de archivo y abre con la aplicación adecuada
			mime_type=$(xdg-mime query filetype "$arg")
			case "$mime_type" in
				image/*)
					eog "$arg"
					;;
				*)
					open_file "$arg"
					;;
			esac
		else
			echo "Error: '$arg' no es un archivo ni un directorio válido."
		fi
	done
fi


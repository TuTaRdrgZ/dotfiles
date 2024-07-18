# Dotfiles

Este repositorio contiene la configuración personalizada para mi entorno de desarrollo. Utilizo GNU Stow para gestionar y desplegar estos archivos de configuración. 

## Estructura del Repositorio

El repositorio está organizado de la siguiente manera:
```
dotfiles/
├── nvim/
│   ├── .config
│   │   └── nvim
│   │       ├── init.lua
│   │       └── lua
│   │           ├── keymaps.lua
│   │           ├── options.lua
│   │           └── plugins
│   │               └── init.lua
│   └── ...
├── fastfetch/
│   └── .config
│       └── fastfetch
│           └── config.jsonc
├── scripts/
│   └── .local
│       └── bin
│           └── open.sh
├── wezterm/
│   ├── .config
│   │   └── wezterm
│   │       ├── config
│   │       │   └── general.lua
│   │       └── themes
│   │           └── kanagawa.lua
│   └── .wezterm.lua
|── zsh/
|   └── .zshrc
...
```

Cada subdirectorio contiene archivos de configuración para diferentes aplicaciones y entornos. Los nombres de los archivos y directorios son los que se utilizarán como enlaces simbólicos en tu directorio home.

## Instalación

### Requisitos

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Git](https://git-scm.com/)
- [WezTerm](https://wezfurlong.org/wezterm/index.html)
- [Neovim](https://neovim.io/)
- [FastFetch](https://github.com/fastfetch-cli/fastfetch)

### Pasos

1. **Clona el repositorio:**

   ```bash
   git clone https://github.com/TuTaRdrgZ/dotfiles.git ~/.dotfiles
2. **Navega al directorio de dotfiles**
   ```bash
   cd ~/.dotfiles
3. **Usa Stow para instalar las configuraciones**
  ```bash
  stow nvim
  stow zsh
  stow wezterm
  stow . # para instalar todo
```
## Uso

Una vez que hayas instalado las configuraciones usando stow, los archivos de configuración serán aplicados de inmediato.
Actualizaciones

Para actualizar la configuración, realiza cambios en los archivos dentro de los subdirectorios correspondientes y luego vuelve a ejecutar stow si es necesario.

## Desinstalación

Para eliminar la configuración gestionada por stow, puedes utilizar el comando stow -D seguido del nombre del directorio:
```bash
stow -D bash
stow -D vim
stow -D git
```
Esto eliminara todos los enlaces simbolicos creados por Stow.

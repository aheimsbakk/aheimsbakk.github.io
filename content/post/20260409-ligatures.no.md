---
tags:
  - howto
date: 2026-04-03
categories:
  - blog
type: post
subtitle: Ligatur i Visual Studio Code og Kitty
title: Penere fonter
---
Penere fonter i Visual Studio Code og terminalen ved å bruke `Cascadia Code`.

<!--more-->

Installer Microsfot ligature fonten [`Cascadia Code`](https://github.com/microsoft/cascadia-code) med:

- Linux: `sudo apt install fonts-cascadia-code`
- macOS: `brew install --cask font-cascadia-code`

## Terminal

Dette er konfigurasjonen for Kitty. Kitty tar den i bruk med en gang.

```
font_family      family='Cascadia Code' variable_name=CascadiaCodeRoman style=Regular
```
## VSCode

I Visual Studio Code, åpne konfigurasjonen og søk etter ligature. Velg `Edit in settings.json` under **Editor: Font ligatures**. Sørg for å sette dette i json konfigurasjonen.

```json
"editor.fontLigatures": true
```


---
tags:
  - howto
date: 2026-04-10
categories:
  - blog
type: post
subtitle: Ligatur i Visual Studio Code og Kitty
title: Ligaturfonter for koding
---
Ligaturfonter i Visual Studio Code og terminalen ved å bruke `Cascadia Code`.

<!--more-->

Installer Microsfot ligaturfonten [`Cascadia Code`](https://github.com/microsoft/cascadia-code) med:

- Linux: `sudo apt install fonts-cascadia-code`
- macOS: `brew install --cask font-cascadia-code`

## Terminal

Konfigurasjon i for Kitty terminal. Legg til konfigurasjonen i `kitty.conf`.  Last så konfigurasjonen på ny.

```
font_family      family='Cascadia Code' variable_name=CascadiaCodeRoman style=Regular
```
## VSCode

I Visual Studio Code, åpne konfigurasjonen og søk etter ligature. Velg `Edit in settings.json` under **Editor: Font ligatures**. Oppdater `editor.fontLigatures` i json konfigurasjonen.

```json
"editor.fontLigatures": true
```

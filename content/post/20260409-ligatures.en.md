---
tags:
  - howto
date: 2026-04-10
categories:
  - blog
type: post
subtitle: Ligatures in Visual Studio Code and Kitty
title: Ligature Fonts for Coding
---

*Automatic traslated by gemma4:e4b.*

Ligature fonts in Visual Studio Code and the terminal using `Cascadia Code`.

<!--more-->

Install the Microsoft ligature font [`Cascadia Code`](https://github.com/microsoft/cascadia-code) with:

- Linux: `sudo apt install fonts-cascadia-code`
- macOS: `brew install --cask font-cascadia-code`

## Terminal

Configuration for the Kitty terminal. Add the configuration to `kitty.conf` and then reload the configuration.

```
font_family      family='Cascadia Code' variable_name=CascadiaCodeRoman style=Regular
```

## VSCode

In Visual Studio Code, open the configuration and search for ligature. Select `Edit in settings.json` under **Editor: Font ligatures**. Update `editor.fontLigatures` in the json configuration.

```json
"editor.fontLigatures": true
```

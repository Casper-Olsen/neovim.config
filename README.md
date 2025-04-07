# Casper-Olsen/neovim.config

## Introduction

*This is originally a fork of [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim).*

## Installation

### Install

Neovim's configurations are located under the following paths, depending on your OS:

| OS | PATH |
| :- | :--- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows (cmd)| `%localappdata%\nvim\` |
| Windows (powershell)| `$env:LOCALAPPDATA\nvim\` |

#### Clone kickstart.nvim

<details><summary> Linux and Mac </summary>

```sh
git clone https://github.com/Casper-Olsen/neovim.config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

<details><summary> Windows </summary>

If you're using `cmd.exe`:

```
git clone https://github.com/Casper-Olsen/neovim.config.git "%localappdata%\nvim"
```

If you're using `powershell.exe`

```
git clone https://github.com/Casper-Olsen/neovim.config.git "${env:LOCALAPPDATA}\nvim"
```

</details>

### Post Installation

Start Neovim

```sh
nvim
```

That's it! Lazy will install all the plugins you have. Use `:Lazy` to view
the current plugin status. Hit `q` to close the window.


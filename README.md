## Introduction

`compile-mode.nvim` is a Neovim plugin which emulates the features of Emacs'
[Compilation
Mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html).
It allows you to run commands which are output into a special buffer, and then
rerun that command over and over again as much as you need.

## Features

[Compile Mode Features](https://github.com/ej-shafran/compile-mode.nvim/assets/116496520/5541b9dd-70b7-4647-9c13-9e57813dac27)

### New Features

- **Command History Management**: Automatic tracking of command history with frequency-based sorting
- **Bookmark System**: Save frequently used commands as bookmarks with file type and project filters
- **UI Manager Buffer**: neogit/oil-style buffer interface for managing history and bookmarks
- **fzf-lua Integration**: Fuzzy search through command history and bookmarks
- **Custom Input System**: Modern floating window input instead of vim.ui.input
- **Configurable History Limit**: Control the maximum number of commands stored in history

## Installation

Use your favorite plugin manager. `compile-mode.nvim` depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

> [!WARNING]
>
> `compile-mode.nvim` only supports Neovim versions v0.10.0 and higher, and isn't expected to work for earlier versions.

Here's an example of a [Lazy](https://github.com/folke/lazy.nvim) config for
`compile-mode.nvim`:

```lua
return {
  "ej-shafran/compile-mode.nvim",
  version = "^5.0.0",
  -- you can just use the latest version:
  -- branch = "latest",
  -- or the most up-to-date updates:
  -- branch = "nightly",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- optional: for fuzzy searching history and bookmarks
    -- "ibhagwan/fzf-lua",
    -- if you want to enable coloring of ANSI escape codes in
    -- compilation output, add:
    -- { "m00qek/baleia.nvim", tag = "v1.3.0" },
  },
  config = function()
    ---@type CompileModeOpts
    vim.g.compile_mode = {
        -- if you use something like `nvim-cmp` or `blink.cmp` for completion,
        -- set this to fix tab completion in command mode:
        -- input_word_completion = true,

        -- to add ANSI escape code support, add:
        -- baleia_setup = true,

        -- to make `:Compile` replace special characters (e.g. `%`) in
        -- the command (and behave more like `:!`), add:
        -- bang_expansion = true,
        
        -- maximum number of commands to keep in history (default: 100)
        -- max_history_size = 100,
        
        -- use custom floating input instead of vim.ui.input (default: true)
        -- use_custom_input = true,
    }
  end
}
```

## Usage

### Basic Commands

- `:Compile [command]` - Run a compilation command
- `:Recompile` - Rerun the last compilation command
- `:NextError` / `:PrevError` - Navigate through compilation errors
- `:CurrentError` - Jump to the current error
- `:FirstError` - Jump to the first error
- `:QuickfixErrors` - Load errors into quickfix list

### History and Bookmarks

- `:CompileManager` - Open the manager UI (shows history by default)
- `:CompileHistory` - Open history view in manager
- `:CompileBookmarks` - Open bookmarks view in manager
- `:CompileAddBookmark <name> <command>` - Add a new bookmark
- `:CompileClearHistory` - Clear all command history

### Manager UI Keybindings

When in the manager buffer:
- `<CR>` - Execute command under cursor
- `t` - Toggle between history and bookmarks view
- `r` - Refresh the view
- `d` - Delete entry under cursor
- `b` - Bookmark current command (history view only)
- `q` - Close manager
- `?` - Show help

### fzf-lua Integration (Optional)

If you have [fzf-lua](https://github.com/ibhagwan/fzf-lua) installed:

- `:CompileFzfHistory` - Fuzzy search command history
- `:CompileFzfBookmarks` - Fuzzy search bookmarks
- `:CompileFzfRecent [N]` - Show N most recent commands (default: 20)
- `:CompileFzfCombined` - Search both history and bookmarks

In the fzf picker:
- `<CR>` - Execute selected command
- `<Ctrl-D>` - Delete selected entry

## Contributing

Contributions are welcome in the form of GitHub issues and pull requests.

For contributing details see [CONTRIBUTING.md](CONTRIBUTING.md).

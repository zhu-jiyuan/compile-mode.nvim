# New Features Documentation

This document describes the new features added to compile-mode.nvim as part of the refactoring project.

## Command History

The plugin now tracks all compile commands you run, including:
- Command execution frequency
- Last used timestamp
- Directory where the command was executed

### Configuration

```lua
vim.g.compile_mode = {
  -- Maximum number of commands to keep in history (default: 100)
  max_history = 100,
  -- ... other options
}
```

### Commands

- `:CompileHistory` - Open the interactive history/bookmark manager
- `:CompileToggleManager` - Toggle the manager window
- `:CompilePickHistory` - Use fzf-lua to pick and execute from history
- `:CompilePickAll` - Use fzf-lua to pick from both history and bookmarks

### History Manager UI

The history manager displays commands sorted by frequency (most used first):

```
# Command History (sorted by frequency)
# Press <Tab> to switch to bookmarks, <CR> to execute, d to delete

[  5] make test (in /home/user/project)
[  3] npm run build (in /home/user/webapp)
[  1] echo hello
```

**Keymaps in manager buffer:**
- `<CR>` - Execute the command under cursor
- `d` - Delete the entry under cursor
- `<Tab>` - Switch between history and bookmarks view
- `q` - Close the manager
- `r` - Refresh the view

## Bookmarks

You can now save frequently-used commands as bookmarks with different matching strategies:

### Bookmark Types

1. **Filetype bookmarks** - Matched by file type
2. **Project bookmarks** - Matched by project path (supports patterns)
3. **Pattern bookmarks** - Always available (regex-based)

### Creating Bookmarks

```lua
local compile_mode = require("compile-mode")

-- Add a filetype-specific bookmark
compile_mode.add_bookmark({
  name = "run-python",
  command = "python %",
  type = "filetype",
  matcher = "python",
  description = "Run current Python file"
})

-- Add a project-specific bookmark
compile_mode.add_bookmark({
  name = "project-test",
  command = "npm test",
  type = "project",
  matcher = "/home/user/myproject",
  description = "Run project tests"
})

-- Add a pattern bookmark (always available)
compile_mode.add_bookmark({
  name = "grep-todos",
  command = "grep -rn TODO .",
  type = "pattern",
  matcher = ".*",
  description = "Find all TODOs"
})
```

### Commands

- `:CompilePickBookmarks` - Use fzf-lua to pick and execute from bookmarks

### Getting Matching Bookmarks

```lua
local bookmarks = require("compile-mode.bookmarks")

-- Get bookmarks for current filetype
local ft_bookmarks = bookmarks.get_matching(vim.bo.filetype, nil)

-- Get bookmarks for current project
local proj_bookmarks = bookmarks.get_matching(nil, vim.fn.getcwd())

-- Get all bookmarks
local all = bookmarks.get_all()
```

## FZF-lua Integration

The plugin now integrates with fzf-lua for fuzzy finding commands:

### Features

- Preview command details (execution count, last used, directory)
- Delete entries with `<Ctrl-d>`
- Fuzzy search across command text

### Requirements

Install [fzf-lua](https://github.com/ibhagwan/fzf-lua):

```lua
-- Using lazy.nvim
{
  "ej-shafran/compile-mode.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "ibhagwan/fzf-lua", -- Optional but recommended
  }
}
```

## Custom Input Buffer

The compile command input now uses a custom mini floating window instead of `vim.ui.input`:

### Features

- Floating window with rounded border
- Tab completion support
- Escape to cancel
- Enter to submit

### Keymaps in Input Buffer

- `<CR>` - Submit input and run command
- `<Esc>` - Cancel input
- `<Tab>` - Trigger completion

## Lua Implementation

All new features are implemented in pure Lua:

- `lua/compile-mode/history.lua` - Command history management
- `lua/compile-mode/bookmarks.lua` - Bookmark system
- `lua/compile-mode/manager.lua` - Interactive UI buffer
- `lua/compile-mode/fzf.lua` - FZF-lua integration
- `lua/compile-mode/input.lua` - Custom input buffer

## Unit Tests

Unit tests have been added for the new modules:

- `spec/history_spec.lua` - Tests for history module
- `spec/bookmarks_spec.lua` - Tests for bookmarks module

Run tests with:

```bash
make test
```

## API

### Setup Function

```lua
local compile_mode = require("compile-mode")

-- Initialize with custom options
compile_mode.setup({
  max_history = 50,  -- Limit history to 50 commands
})
```

### Programmatic Access

```lua
local compile_mode = require("compile-mode")

-- Get history module
local history = compile_mode.get_history()
local entries = history.get_sorted()

-- Get bookmarks module  
local bookmarks = compile_mode.get_bookmarks()
local all_bookmarks = bookmarks.get_all()

-- Add commands to history manually
history.add("custom command", "/path/to/dir")

-- Remove from history
history.remove("command to remove")
```

## Example Configuration

```lua
return {
  "ej-shafran/compile-mode.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "ibhagwan/fzf-lua", -- Optional
  },
  config = function()
    local compile_mode = require("compile-mode")
    
    -- Setup with custom history limit
    compile_mode.setup({
      max_history = 100,
    })
    
    -- Add some default bookmarks
    compile_mode.add_bookmark({
      name = "lua-test",
      command = "busted .",
      type = "filetype",
      matcher = "lua",
    })
    
    compile_mode.add_bookmark({
      name = "make-all",
      command = "make -j8",
      type = "pattern",
      matcher = ".*",
    })
    
    -- Setup keymaps
    vim.keymap.set("n", "<leader>cc", ":Compile<CR>", { desc = "Compile" })
    vim.keymap.set("n", "<leader>cr", ":Recompile<CR>", { desc = "Recompile" })
    vim.keymap.set("n", "<leader>ch", ":CompilePickHistory<CR>", { desc = "Pick from history" })
    vim.keymap.set("n", "<leader>cb", ":CompilePickBookmarks<CR>", { desc = "Pick bookmark" })
    vim.keymap.set("n", "<leader>cm", ":CompileToggleManager<CR>", { desc = "Toggle manager" })
  end
}
```

## Migration Notes

All existing functionality remains unchanged. The new features are additive:

- Existing commands (`:Compile`, `:Recompile`, etc.) work exactly as before
- History tracking is automatic and transparent
- The custom input buffer is a drop-in replacement for `vim.ui.input`
- New commands are prefixed with `Compile` to avoid conflicts

## Persistence

History and bookmarks are automatically persisted to:

- History: `~/.local/share/nvim/compile-mode-history.json`
- Bookmarks: `~/.local/share/nvim/compile-mode-bookmarks.json`

These files are in JSON format and can be manually edited if needed.

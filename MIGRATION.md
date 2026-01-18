# Migration Guide

## Overview

This guide helps you migrate to the new version of compile-mode.nvim with the new features. **Good news**: No migration is required! The plugin is 100% backward compatible.

## What's New?

The refactoring adds powerful new features while keeping all existing functionality:

1. **Command History** - Automatic tracking of all compilation commands
2. **Bookmarks** - Save frequently used commands
3. **UI Manager** - Interactive buffer for managing commands (neogit/oil style)
4. **fzf-lua Integration** - Fuzzy search through history and bookmarks
5. **Custom Input** - Modern floating window for command input

## Do I Need to Change Anything?

**No!** Everything works exactly as before. The new features are additions, not replacements.

## Quick Start with New Features

### Step 1: Update Your Configuration (Optional)

```lua
vim.g.compile_mode = {
  -- Your existing config stays the same
  default_command = "make -k ",
  
  -- Optionally add new options:
  max_history_size = 100,     -- Max commands in history (default: 100)
  use_custom_input = true,    -- Use floating input (default: true)
}
```

### Step 2: Add Keybindings (Optional)

```lua
-- Open the manager UI
vim.keymap.set("n", "<leader>cm", "<cmd>CompileManager<cr>")

-- If you have fzf-lua installed
vim.keymap.set("n", "<leader>cfh", "<cmd>CompileFzfHistory<cr>")
vim.keymap.set("n", "<leader>cfb", "<cmd>CompileFzfBookmarks<cr>")
```

### Step 3: Start Using!

Just use `:Compile` as normal. History will automatically build up. That's it!

## Features You Can Use Right Away

### 1. Command History (Automatic)

Every time you run `:Compile`, the command is saved automatically.

View your history:
```vim
:CompileHistory
```

Or with fzf-lua:
```vim
:CompileFzfHistory
```

### 2. Add Bookmarks

Save a command as a bookmark:
```vim
:CompileAddBookmark build make -j4
:CompileAddBookmark test npm test
```

View bookmarks:
```vim
:CompileBookmarks
```

Or with fzf-lua:
```vim
:CompileFzfBookmarks
```

### 3. Use the Manager UI

Open the interactive manager:
```vim
:CompileManager
```

In the manager:
- Press `<CR>` to execute a command
- Press `t` to toggle between history and bookmarks
- Press `b` to bookmark a command from history
- Press `d` to delete an entry
- Press `?` for help
- Press `q` to close

## Disabling New Features

If you prefer the old input style:

```lua
vim.g.compile_mode = {
  use_custom_input = false,  -- Use vim.ui.input instead
}
```

You can simply ignore the new commands and use the plugin as before.

## Advanced Usage

### Programmatically Add Bookmarks

```lua
local bookmarks = require("compile-mode.bookmarks")

bookmarks.add({
  name = "build-release",
  command = "cmake --build build --config Release",
  filetype = { "c", "cpp" },
  description = "Build in Release mode",
})
```

### Access History Programmatically

```lua
local history = require("compile-mode.history")

-- Get most frequent commands
local commands = history.get_sorted()
for _, cmd in ipairs(commands) do
  print(cmd.command, cmd.frequency)
end

-- Get recent commands
local recent = history.get_recent(10)
```

### Export/Import Bookmarks

Share bookmarks with your team:

```lua
local bookmarks = require("compile-mode.bookmarks")

-- Export to file
local data = bookmarks.export()
local file = io.open("bookmarks.json", "w")
file:write(vim.json.encode(data))
file:close()

-- Import from file
local file = io.open("bookmarks.json", "r")
local content = file:read("*all")
file:close()
bookmarks.import(vim.json.decode(content))
```

## FAQ

### Q: Will my existing `:Compile` commands still work?
**A:** Yes, 100%. Nothing changes in existing behavior.

### Q: Where is the history stored?
**A:** In `~/.local/share/nvim/compile-mode-history.json` (or your configured data directory).

### Q: Where are bookmarks stored?
**A:** In `~/.local/share/nvim/compile-mode-bookmarks.json`.

### Q: Do I need fzf-lua?
**A:** No, it's optional. The manager UI works without it. fzf-lua just adds fuzzy search capabilities.

### Q: Can I disable the new input system?
**A:** Yes, set `use_custom_input = false` in your config.

### Q: Will my history survive Neovim restarts?
**A:** Yes, it's saved to disk automatically.

### Q: How do I clear my history?
**A:** Use `:CompileClearHistory` or `require("compile-mode.history").clear()`.

### Q: Can I filter commands by file type?
**A:** Yes! Both history and bookmarks support file type filtering.

### Q: What if I hit the history size limit?
**A:** The least-used commands are automatically removed to make room for new ones.

## Getting Help

- Open the manager with `:CompileManager`
- Press `?` for help
- Check `examples/advanced_config.lua` for more examples
- See `REFACTORING_SUMMARY.md` for technical details

## Reporting Issues

If something doesn't work as expected:
1. Check if it works with `use_custom_input = false`
2. Look for error messages in `:messages`
3. Open an issue on GitHub with:
   - Your configuration
   - Steps to reproduce
   - Error messages

## Summary

**You don't need to do anything to keep using compile-mode.nvim as before.** The new features are additions that enhance your workflow when you're ready to use them.

Happy compiling! 🚀

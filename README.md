# minimock.nvim

A Neovim plugin to generate Go mocks using [minimock](https://github.com/gojuno/minimock) directly from your editor.

It eliminates the need to manually type long CLI commands by automatically detecting the **interface**, **package**, and **module** context using Treesitter.

## Requirements

1.  **Neovim** >= 0.9.0
2.  **minimock** CLI tool installed and available in your `$PATH`.
    ```bash
    go install github.com/gojuno/minimock/v3/cmd/minimock@latest
    ```
3.  **Treesitter** with the Go parser installed.
    ```vim
    :TSInstall go
    ```

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "AEKDA/minimock.nvim", -- Replace with your actual repo URL
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    {
      "<leader>cm",
      function()
        require("minimock").generate_mock()
      end,
      desc = "Generate Minimock",
      mode = "n",
    },
  },
  -- Optional: if you want to use the setup function
  config = function()
      require("minimock").setup()
  end
}
```

## Usage

1.  Open a Go file.
2.  Place your cursor anywhere inside an **interface definition**:
    ```go
    type MyService interface {
        // cursor can be here
        DoSomething(ctx context.Context) error
    }
    ```
3.  Press your hotkey (e.g., `<leader>cm`).
4.  A floating window will appear with the suggested output path.
    *   *Default behavior:* It creates a `mocks/` subfolder inside the current package directory.
5.  Press **Enter** to confirm or edit the path if necessary.

## ⚙️ How it works

When triggered, the plugin:
1.  **Parses the AST** to find the interface name (`MyService`).
2.  **Locates `go.mod`** to determine the module name (`gitlab.com/my/repo`).
3.  **Calculates the relative path** of the current file (`internal/services/sender`).
4.  **Constructs the command**:
    ```bash
    minimock -i gitlab.com/my/repo/internal/services/sender.MyService \
             -o internal/services/sender/mocks/my_service_mock.go \
             -n MyServiceMock \
             -p mocks
    ```

## 📜 License

MIT

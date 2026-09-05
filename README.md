# Fluent Renewed - Soluna Development

## Installation

You can load Fluent through a GitHub Release:

```lua
local Library = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/Soluna-Development/Library/releases/latest/download/Fluent.luau", true))()
```

```lua
local Library = loadstring(game:HttpGetAsync("https://github.com/Soluna-Development/Library/releases/latest/download/Fluent.luau", true))()
```

To create the Fluent.luau:

```bash
lune run Lune/Build/init.luau bundle input=default.project.json script-output=Fluent.luau minify=false ci-mode=true
```

## Credits

- [Soluna Development](https://github.com/Soluna-Development) - The continuation of Fluent Renewed
- [Master Oogway](https://github.com/Soluna-Development/Library) - The master mind behind Fluent Renewed
- [dawid](https://github.com/dawid-scripts/Fluent) - The master mind behind Fluent
- [Lucide](https://github.com/lucide-icons), [Phosphor](https://github.com/phosphor-icons) - The sexy icons
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) - Assets for the UI, some of the code
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) - Code for most of the elements, save manager
- [7kayoh/Acrylic](https://github.com/7kayoh/Acrylic) - Porting richie0866's acrylic module to lua
- [Latte Softworks & Kotera](https://github.com/latte-soft/wax/) - Bundler
- [Pepsied-5229/Pepsi-UI-Library](https://github.com/Pepsied-5229/Pepsi-UI-Library) - Inspiration for new features, some of the code

[![Fluent Renewed - Soluna Development](https://uibin.orqan.xyz/api/card?id=699e1db4-f5b3-4616-9973-417f92fdae91&theme=white)](https://uibin.orqan.xyz/library/699e1db4-f5b3-4616-9973-417f92fdae91)
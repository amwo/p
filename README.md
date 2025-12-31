## Usage

```
nix run . -- athena
```

## Zsh

### Arch Linux
```
# Check existing zsh path
ls -l ~/.nix-profile/bin/zsh

# Register to /etc/shells
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells

# Set as default shell
chsh -s "$HOME/.nix-profile/bin/zsh"
```

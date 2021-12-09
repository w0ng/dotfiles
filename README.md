# dotfiles

## Usage


Install https://www.gnu.org/software/stow/

```
brew install stow
```


Clone this repo to $HOME directory:

```
git clone https://github.com/w0ng/dotfiles.git ~/dotfiles && cd ~/dotfiles
```

Use `stow` to manage symlinking e.g. for config files in `git/`:

```
stow git/
```

Config files are now symlinked:
```
$ ls -la ~ | grep .git
lrwxr-xr-x   1 andrew  staff     34  9 Dec 21:33 .gitattributes_global -> dotfiles/git/.gitattributes_global
lrwxr-xr-x   1 andrew  staff     23  9 Dec 21:33 .gitconfig -> dotfiles/git/.gitconfig
lrwxr-xr-x   1 andrew  staff     30  9 Dec 21:33 .gitignore_global -> dotfiles/git/.gitignore_global
```

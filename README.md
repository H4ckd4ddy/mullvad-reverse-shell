# mullvad-reverse-shell
Quick and dirty reverse shell through Mullvad

### Installation

```bash
profile=~/.$(basename $SHELL)rc
curl https://raw.githubusercontent.com/H4ckd4ddy/mullvad-reverse-shell/master/rshell.sh >> $profile
. $profile
```
**Remeber to always review script before executing this kind of command in your shell**

or

Just add `rshell.sh` content in your zshrc, bashrc or whatever-rc


### Usage

- Enable Mullvad connection
- `rshell`

### Clear ports

`rshell clear`
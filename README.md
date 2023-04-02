# mullvad-reverse-shell
Quick and dirty reverse shell through Mullvad

## Installation

```bash
profile=~/.$(basename $SHELL)rc
curl https://raw.githubusercontent.com/H4ckd4ddy/mullvad-reverse-shell/master/rshell.sh >> $profile
. $profile
```
**Remeber to always review script before executing this kind of command in your shell**

or

Just add `rshell.sh` content in your zshrc, bashrc or whatever-rc


## Usage

### Reverse shell

- Enable Mullvad connection
- `rshell`

### Expose port trough SSH

It will create a container with SSH server to handle tunnel

- Enable Mullvad connection
- `rshell nat [remote_port]`

## Clear ports

`rshell clear`
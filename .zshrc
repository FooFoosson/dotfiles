# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel9k/powerlevel9k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-vi-mode)

DISABLE_AUTO_UPDATE=true
source $ZSH/oh-my-zsh.sh

# User configuration

# nmcli r wifi off

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user dir)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(dir_writable vcs status background_jobs time )
POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export DDAD_PATH=~/ddad
export PATH="/home/kagrenac/bin:$PATH"
export PATH="/home/kagrenac/Downloads/pintos/src/utils:$PATH"
export EDITOR='vim'
export VISUAL='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias gitupdate='git fetch --prune && git checkout origin/master && git submodule foreach "git fetch --prune && git checkout origin/master || :" && cd -'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls'

alias force='git push --force'
alias push='git push'
alias add='git add'
alias status='git status'
alias continue='git rebase --continue'
alias abort='git rebase --abort'
alias pull='git pull'
alias checkout='git checkout'
alias branch='git checkout -b'
alias stash='git stash'
alias unstash='git stash apply'
alias log='git log'
alias show='git show'
alias update='git fetch && git rebase origin/master'
alias unstage='git restore --staged'

function restore(){
    git restore --source=origin/master $1
}

function rebase(){
    git rebase -i HEAD~$1
}
function commit(){
    git commit -m "$@"
}
function search(){
    grep -rnw ./ -e "$1"
}

# worktree <path-to-repo>  -> create ./<repo>_<N+1> worktree off main, cd in, run claude
# worktree remove [path]   -> remove worktree (confirms if work would be lost)
function worktree(){
    if [[ "$1" == "remove" ]]; then
        shift
        _worktree_remove "$@"
        return $?
    fi

    local repo="$1"
    if [[ -z "$repo" ]]; then
        echo "usage: worktree <path-to-repo>" >&2
        echo "       worktree remove [path]" >&2
        return 1
    fi
    if [[ ! -d "$repo" ]] || ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
        echo "worktree: '$repo' is not a git repository" >&2
        return 1
    fi

    # main worktree of the given repo, and the name we base new dirs on
    local main_wt name
    main_wt="$(git -C "$repo" worktree list --porcelain 2>/dev/null | head -1 | cut -d' ' -f2-)"
    [[ -n "$main_wt" ]] || main_wt="${repo:A}"
    name="${${main_wt:A}:t}"
    name="${name%.git}"

    # always branch off main (fall back to master), preferring the remote-tracking tip
    local base r
    for r in refs/remotes/origin/main refs/heads/main refs/remotes/origin/master refs/heads/master; do
        if git -C "$main_wt" show-ref --verify --quiet "$r"; then
            base="${r#refs/remotes/}"; base="${base#refs/heads/}"
            break
        fi
    done
    if [[ -z "$base" ]]; then
        echo "worktree: no main or master branch found in '$main_wt'" >&2
        return 1
    fi

    # highest existing <name>_<number>, counting both directories here and branches
    local d suffix max=0
    for d in ./${name}_*(N/) ${(f)"$(git -C "$main_wt" for-each-ref --format='%(refname:short)' "refs/heads/${name}_*")"}; do
        suffix="${${d:t}#${name}_}"
        [[ "$suffix" == <-> ]] || continue
        (( 10#$suffix > max )) && max=$((10#$suffix))
    done

    local target="$PWD/${name}_$((max + 1))"
    git -C "$main_wt" worktree add --no-track -b "${target:t}" "$target" "$base" || return 1

    cd "$target" || return 1
    claude
}

function _worktree_remove(){
    local target="${1:-$PWD}"
    if [[ ! -d "$target" ]] || ! git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "worktree: '$target' is not a git worktree" >&2
        return 1
    fi

    local root git_dir common_dir main_wt
    root="$(git -C "$target" rev-parse --show-toplevel)"
    git_dir="$(git -C "$root" rev-parse --absolute-git-dir)"
    common_dir="$(git -C "$root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
    if [[ "${git_dir:A}" == "${common_dir:A}" ]]; then
        echo "worktree: '$root' is the main worktree, not a linked one - refusing to remove" >&2
        return 1
    fi
    main_wt="$(git -C "$root" worktree list --porcelain | head -1 | cut -d' ' -f2-)"

    # collect anything that would be lost
    local -a problems
    local dirty branch upstream ahead unpushed

    dirty="$(git -C "$root" status --short)"
    [[ -n "$dirty" ]] && problems+=("uncommitted changes / untracked files:"$'\n'"$(print -r -- "$dirty" | sed 's/^/      /')")

    branch="$(git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null)"
    if [[ -z "$branch" ]]; then
        # detached HEAD only loses work if no branch/remote ref contains it
        if [[ -z "$(git -C "$root" for-each-ref --contains HEAD --count=1 refs/heads refs/remotes 2>/dev/null)" ]]; then
            problems+=("detached HEAD at $(git -C "$root" rev-parse --short HEAD) - commits are on no branch")
        fi
    elif [[ -n "$(git -C "$root" remote)" ]]; then
        upstream="$(git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"
        if [[ -n "$upstream" ]]; then
            ahead="$(git -C "$root" rev-list --count "$upstream..HEAD" 2>/dev/null)"
            (( ahead > 0 )) && problems+=("$ahead commit(s) on '$branch' not pushed to '$upstream'")
        else
            unpushed="$(git -C "$root" rev-list --count HEAD --not --remotes 2>/dev/null)"
            if (( unpushed > 0 )); then
                problems+=("'$branch' has no upstream and $unpushed commit(s) are on no remote")
            fi
        fi
    fi

    local force=()
    if (( ${#problems} )); then
        local p
        print -r -- "worktree: '$root' has work that would be lost:"
        for p in "${problems[@]}"; do print -r -- "  - $p"; done
        local reply
        read -r "reply?Remove it anyway? [y/N] "
        if [[ "$reply" != [yY]* ]]; then
            echo "worktree: aborted"
            return 1
        fi
        force=(--force)
    fi

    # step out of the worktree before deleting it
    [[ "$PWD" == "$root"(|/*) ]] && cd "${root:h}"

    git -C "$main_wt" worktree remove $force "$root" || return 1
    [[ -d "$root" ]] && rm -rf "$root"
    git -C "$main_wt" worktree prune
    echo "worktree: removed $root${branch:+ (branch '$branch' kept)}"
}

function x()
{
    echo $@
    if [ -f "$@" ] ; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *)           echo "'$1' cannot be extracted via ex()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

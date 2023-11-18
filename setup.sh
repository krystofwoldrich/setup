#!/bin/zsh

prepend() {
  content=$1
  file=$2
  echo "${content}\n$(cat $file)" > "$file"
}

append() {
  content=$1
  file=$2
  echo "$content" >> "$file"
}

# --dry-run
# The script won't make any changes to your system
# only prints out what it would do
if [[ "$1" == "--dry-run" ]]; then
  IS_DRY_RUN=true
else
  IS_DRY_RUN=false
fi

# Preconditions
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "This script is only for macOS"
  exit 1
fi

# Expect zsh
if [[ "$SHELL" != "/bin/zsh" ]]; then
  echo "This script is only for zsh"
  exit 1
fi

# Install xcode-select
xcodeToolsPath=$(xcode-select -p)
if [[ "$xcodeToolsPath" == "" ]]; then
  echo "Xcode Tools are not installed"
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo "xcode-select --install"
  else
    xcode-select --install
  fi
else
  echo "Xcode Tools detected at $xcodeToolsPath"
fi

# Check git version
gitPath=$(command -v git)
if [[ "$gitPath" == "" ]]; then
  echo 'git command not found'
else
  echo "git detected at $gitPath"
  git --version
fi

# Homebrew
brewPath=$(command -v brew)
if [[ "$brewPath" == "" ]]; then
  echo 'Homebrew not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  echo "Homebrew detected at $brewPath"
fi

# Oh My Zsh
# check if $HOME/.oh-my-zsh exists
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "Oh My Zsh detected at $HOME/.oh-my-zsh"
else
  echo 'Oh My Zsh not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  else
    export $RUNZSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

# setup nerd fonts
if [[ -d '/opt/homebrew/Library/Taps/homebrew/homebrew-cask-fonts' ]]; then
  echo 'homebrew/cask-fonts detected at /opt/homebrew/Library/Taps/homebrew/homebrew-cask-fonts'
else
  echo 'homebrew/cask-fonts not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'brew tap homebrew/cask-fonts'
  else
    brew tap homebrew/cask-fonts
  fi
fi

# brew install font-hack-nerd-font
if [[ -f "$HOME/Library/Fonts/HackNerdFont-Regular.ttf" ]]; then
  echo 'Hack Nerd Font detected at $HOME/Library/Fonts'
else
  echo 'Hack Nerd Font not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'brew install --cask font-hack-nerd-font'
  else
    brew install --cask font-hack-nerd-font
  fi
fi

# Install powerlevel10k theme
if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  echo "powerlevel10k detected at $HOME/.oh-my-zsh/custom/themes/powerlevel10k"
else
  echo 'powerlevel10k not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k'
  else
    # Download
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    # Set theme
    sed -i '' -e 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k/powerlevel10k"/g' $HOME/.zshrc

    # Init
    prepend '# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
' $HOME/.zshrc

    # Apply config
    append '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' $HOME/.zshrc
    cp config.p10k.zsh $HOME/.p10k.zsh
  fi
fi

# Rubby manager
rbEnvPath=$(command -v rbenv)
if [[ "$rbEnvPath" == "" ]]; then
  echo 'rbenv not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'brew install rbenv ruby-build'
  else
    brew install rbenv ruby-build
    rbenv --version
    rbenv install 3.2.2
    rbenv global 3.2.2

    'eval "$(rbenv init - zsh)"' >> $HOME/.zshrc
  fi
else
  echo "rbenv detected at $rbEnvPath"
fi

# Node manager
if [[ ! -d "$HOME/.nvm" ]]; then
  echo 'nvm not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'brew install nvm'
  else
    brew install nvm
    mkdir ~/.nvm
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
    nvm --version

    echo 'export NVM_DIR="$HOME/.nvm"' >> $HOME/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm' >> $HOME/.zshrc

    nvm install node 21
    if [[ ! -x '/usr/local/bin/node' ]]; then
      if [[ ! -d '/usr/local/bin' ]]; then
        sudo mkdir /usr/local/bin
      fi
      sudo ln -s $(which node) /usr/local/bin/node
    fi
  fi
else
  echo "nvm detected at $HOME/.nvm"
fi

# Python manager
pyenvPath=$(command -v pyenv)
if [[ "$pyenvPath" == "" ]]; then
  echo 'pyenv not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'brew install pyenv'
  else
    brew install pyenv
    pyenv --version
    pyenv install 3.12.0
    pyenv global 3.12.0

    append 'export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
' $HOME/.zshrc
  fi
else
  echo "pyenv detected at $pyenvPath"
fi

# Java manager
if [[ ! -d "$HOME/.sdkman" ]]; then
  echo 'sdkman not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'bash -c "$(curl -fsSL https://get.sdkman.io)"'
  else
    bash -c "$(curl -fsSL https://get.sdkman.io)"
    source "/Users/krystofwoldrich/.sdkman/bin/sdkman-init.sh"
    sdk help
    sdk install java 17.0.9-zulu

    append 'export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
' $HOME/.zshrc
  fi
else
  echo "sdkman detected at $HOME/.sdkman"
fi

# Install VS Code
codePath=$(command -v code)
if [[ "$codePath" == "" ]]; then
  echo 'VS Code not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo 'brew install --cask visual-studio-code'
  else
    brew install --cask visual-studio-code
  fi
else
  echo "VS Code detected at $codePath"
fi

# Install Android Studio
if [[ -x "/Applications/Android Studio.app" ]]; then
  echo 'Android Studio detected at /Applications/Android Studio.app'
else
  echo 'Android Studio not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo "brew install --cask android-studio"
  else
    brew install --cask android-studio

    # Set envs
    append 'export ANDROID_HOME=~/Library/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
' $HOME/.zshrc
  fi
fi

# Install iterm2
if [[ -x "/Applications/iTerm.app" ]]; then
  echo 'iTerm2 detected at /Applications/iTerm.app'
else
  echo 'iTerm2 not found'
  if [[ "$IS_DRY_RUN" == true ]]; then
    echo "brew install --cask iterm2"
  else
    brew install --cask iterm2
  fi
fi

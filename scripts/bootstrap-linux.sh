#!/usr/bin/env bash
# Bootstrap idempotent pour reproduire le setup tpm-aoe + Claude Code + tpm-workflow
# sur une VM Ubuntu Server 24.04 LTS (compatible Debian 12).
#
# Usage :
#   curl -fsSL <ce-fichier> | bash               # one-shot
#   ou : scp ce fichier puis : bash bootstrap-linux.sh
#
# Re-runnable : oui, toutes les étapes vérifient l'existant avant d'agir.
# Customisation : édite les variables sous "## Config" ou exporte-les avant.

set -euo pipefail

# ============================================================
# Config — ajuste si tes forks ont d'autres noms
# ============================================================
GITHUB_USER="${GITHUB_USER:-EnzoVentura}"
AOE_FORK="${AOE_FORK:-${GITHUB_USER}/tpm-aoe}"
TPM_WORKFLOW_FORK="${TPM_WORKFLOW_FORK:-${GITHUB_USER}/tpm-workflow}"
AOE_UPSTREAM="${AOE_UPSTREAM:-Loulen/tpm-aoe}"
TPM_WORKFLOW_UPSTREAM="${TPM_WORKFLOW_UPSTREAM:-Loulen/tpm-workflow}"

LAB_DIR="${LAB_DIR:-$HOME/Documents/Lab}"
AOE_DIR="$LAB_DIR/tpm-aoe"
TPM_WORKFLOW_DIR="$LAB_DIR/tpm-workflow"

SSH_HOST_ALIAS="${SSH_HOST_ALIAS:-github.com-perso}"
SSH_KEY_NAME="${SSH_KEY_NAME:-id_ed25519_perso}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-enzo.venturapro@gmail.com}"
GIT_USER_NAME="${GIT_USER_NAME:-Enzo Ventura}"

INSTALL_CLAUDE_CODE="${INSTALL_CLAUDE_CODE:-yes}"
INSTALL_DOCKER="${INSTALL_DOCKER:-no}"
INSTALL_ZSH="${INSTALL_ZSH:-yes}"
ZSH_THEME_NAME="${ZSH_THEME_NAME:-robbyrussell}"   # robbyrussell, agnoster, ys, etc.

# ============================================================
# Helpers
# ============================================================
COL_BLUE='\033[1;34m'; COL_YEL='\033[1;33m'; COL_RED='\033[1;31m'; COL_GRN='\033[1;32m'; COL_RST='\033[0m'
log()  { printf "${COL_BLUE}[bootstrap]${COL_RST} %s\n" "$*"; }
ok()   { printf "${COL_GRN}[ok]${COL_RST} %s\n" "$*"; }
warn() { printf "${COL_YEL}[warn]${COL_RST} %s\n" "$*"; }
err()  { printf "${COL_RED}[err]${COL_RST} %s\n" "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
pause(){ read -r -p "$1 [Entrée pour continuer, Ctrl-C pour annuler] " _; }

# ============================================================
# 0 — Sanity checks
# ============================================================
log "0/11  Vérifications préalables"
[[ "$(id -u)" -ne 0 ]] || { err "Ne lance pas ce script en root. Utilise un user normal (sudo sera demandé au besoin)."; exit 1; }
have sudo || { err "sudo est requis."; exit 1; }
sudo -v

if grep -qiE 'ubuntu (24|22)' /etc/os-release 2>/dev/null; then
  ok "Ubuntu détectée"
elif grep -qi 'debian' /etc/os-release 2>/dev/null; then
  ok "Debian détectée"
else
  warn "Distribution non testée — le script peut nécessiter des ajustements."
fi

# ============================================================
# 1 — Paquets système
# ============================================================
log "1/11  Paquets système (apt)"
sudo apt-get update -qq
sudo apt-get install -y -q \
  build-essential pkg-config libssl-dev libffi-dev \
  curl wget git tmux jq htop tree unzip zip \
  ca-certificates gnupg lsb-release software-properties-common \
  ripgrep fd-find \
  zsh

# ============================================================
# 2 — Git config minimale
# ============================================================
log "2/11  Configuration git globale"
[[ -n "$(git config --global user.email || true)" ]] || git config --global user.email "$GIT_USER_EMAIL"
[[ -n "$(git config --global user.name  || true)" ]] || git config --global user.name  "$GIT_USER_NAME"
git config --global init.defaultBranch main
git config --global pull.rebase false

# ============================================================
# 3 — GitHub CLI
# ============================================================
log "3/11  GitHub CLI"
if ! have gh; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -q gh
fi
ok "gh : $(gh --version | head -1)"

# ============================================================
# 4 — Rust toolchain via rustup
# ============================================================
log "4/11  Rust toolchain"
if ! have rustup; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"
rustup default stable >/dev/null
rustup component add clippy rustfmt >/dev/null 2>&1 || true
ok "rustc : $(rustc --version)"

# ============================================================
# 5 — Node via fnm + LTS
# ============================================================
log "5/11  Node.js via fnm"
if ! have fnm; then
  curl -fsSL https://fnm.vercel.app/install \
    | bash -s -- --skip-shell --install-dir "$HOME/.local/share/fnm"
fi
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --shell bash)"
fnm install --lts >/dev/null 2>&1 || true
fnm default "$(fnm list 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1)" >/dev/null 2>&1 || true
fnm use default >/dev/null 2>&1 || true
ok "node : $(node --version 2>/dev/null || echo 'pas dans le PATH du script — sera dispo après reload shell')"

# ============================================================
# 6 — Docker (optionnel)
# ============================================================
if [[ "$INSTALL_DOCKER" == "yes" ]]; then
  log "6/11  Docker"
  if ! have docker; then
    sudo install -m 0755 -d /etc/apt/keyrings
    . /etc/os-release
    DISTRO_ID="${ID:-ubuntu}"
    curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${VERSION_CODENAME} stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    warn "Logout/login requis pour que l'appartenance au groupe docker prenne effet."
  fi
else
  log "6/11  Docker (sauté — passe INSTALL_DOCKER=yes pour l'installer)"
fi

# ============================================================
# 7 — SSH key + config + ajout à GitHub
# ============================================================
log "7/11  SSH keys"
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"

if [[ ! -f "$HOME/.ssh/$SSH_KEY_NAME" ]]; then
  log "Génération d'une nouvelle clé SSH ($SSH_KEY_NAME)"
  ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL ($(hostname))" -f "$HOME/.ssh/$SSH_KEY_NAME" -N ""
fi
chmod 600 "$HOME/.ssh/$SSH_KEY_NAME"
chmod 644 "$HOME/.ssh/${SSH_KEY_NAME}.pub"

if ! grep -q "Host $SSH_HOST_ALIAS" "$HOME/.ssh/config" 2>/dev/null; then
  cat >> "$HOME/.ssh/config" <<EOF

Host $SSH_HOST_ALIAS
    HostName github.com
    User git
    IdentityFile ~/.ssh/$SSH_KEY_NAME
    IdentitiesOnly yes
EOF
  chmod 600 "$HOME/.ssh/config"
fi

ssh-keyscan -t ed25519,rsa github.com 2>/dev/null >> "$HOME/.ssh/known_hosts"
sort -u "$HOME/.ssh/known_hosts" -o "$HOME/.ssh/known_hosts"

# Test d'auth + ajout à GitHub si gh est loggé
if ssh -o BatchMode=yes -o ConnectTimeout=5 -T "$SSH_HOST_ALIAS" 2>&1 | grep -q "successfully authenticated"; then
  ok "Clé SSH déjà reconnue par GitHub"
else
  if gh auth status >/dev/null 2>&1; then
    log "Ajout de la clé sur GitHub via gh CLI"
    gh ssh-key add "$HOME/.ssh/${SSH_KEY_NAME}.pub" --title "$(hostname) (bootstrap)" || warn "ajout via gh a échoué — ajoute manuellement"
  else
    echo
    warn "La clé n'est pas (encore) sur GitHub et gh n'est pas authentifié."
    echo "Deux options :"
    echo "  A) Lance maintenant : gh auth login   (puis relance ce script)"
    echo "  B) Copie-colle cette clé sur https://github.com/settings/keys :"
    echo
    cat "$HOME/.ssh/${SSH_KEY_NAME}.pub"
    echo
    pause "Une fois la clé ajoutée à GitHub, presse Entrée pour continuer"
  fi
fi

# ============================================================
# 8 — Clone des forks
# ============================================================
log "8/11  Clone des forks"
mkdir -p "$LAB_DIR"

clone_or_update() {
  local repo_dir="$1" fork_path="$2" upstream_path="$3"
  if [[ ! -d "$repo_dir/.git" ]]; then
    log "Clone $fork_path -> $repo_dir"
    git clone "git@${SSH_HOST_ALIAS}:${fork_path}.git" "$repo_dir"
  else
    ok "Repo déjà cloné : $repo_dir"
  fi
  if ! git -C "$repo_dir" remote | grep -q '^upstream$'; then
    git -C "$repo_dir" remote add upstream "https://github.com/${upstream_path}.git"
  fi
  git -C "$repo_dir" fetch --all --quiet || warn "fetch a échoué (pas de réseau ?)"
}

clone_or_update "$AOE_DIR"          "$AOE_FORK"          "$AOE_UPSTREAM"
clone_or_update "$TPM_WORKFLOW_DIR" "$TPM_WORKFLOW_FORK" "$TPM_WORKFLOW_UPSTREAM"

# Submodules dans tpm-aoe (notamment contrib/tpm-workflow/ géré séparément)
git -C "$AOE_DIR" submodule update --init --recursive --quiet || warn "init submodules a échoué"

# ============================================================
# 9 — Build aoe + symlink dans /usr/local/bin
# ============================================================
log "9/11  Build aoe (release + serve)"
cd "$AOE_DIR"
cargo build --release --features serve

AOE_BIN="$AOE_DIR/target/release/aoe"
if [[ ! -x "$AOE_BIN" ]]; then
  err "Build raté — pas de binaire à $AOE_BIN"
  exit 1
fi

if [[ "$(readlink -f /usr/local/bin/aoe 2>/dev/null || true)" != "$(readlink -f "$AOE_BIN")" ]]; then
  sudo ln -sfn "$AOE_BIN" /usr/local/bin/aoe
fi
ok "aoe : $(/usr/local/bin/aoe --version 2>&1 | head -1)"

# ============================================================
# 10 — Skills tpm-workflow comme plugin Claude Code (éditable) + Claude Code CLI
# ============================================================
log "10/11  Wiring tpm-workflow comme plugin Claude Code éditable"
mkdir -p "$HOME/.claude/plugins/marketplaces"
LINK="$HOME/.claude/plugins/marketplaces/tpm-workflow"

if [[ -e "$LINK" && ! -L "$LINK" ]]; then
  BACKUP="${LINK}.bak.$(date +%s)"
  warn "$LINK existe et n'est pas un symlink — backup vers $BACKUP"
  mv "$LINK" "$BACKUP"
fi
ln -sfn "$TPM_WORKFLOW_DIR" "$LINK"
ok "Symlink : $LINK -> $TPM_WORKFLOW_DIR (éditer le repo modifie le plugin live)"

# Claude Code CLI
if [[ "$INSTALL_CLAUDE_CODE" == "yes" ]]; then
  if ! have claude; then
    log "Installation Claude Code CLI (npm)"
    npm install -g @anthropic-ai/claude-code
  fi
  ok "claude : $(claude --version 2>/dev/null | head -1 || echo 'installé, login requis')"
fi

# ============================================================
# 11 — zsh + oh-my-zsh + plugins
# ============================================================
if [[ "$INSTALL_ZSH" == "yes" ]]; then
  log "11/11  zsh + oh-my-zsh"

  ZSH_DIR="$HOME/.oh-my-zsh"
  ZSH_CUSTOM_DIR="$ZSH_DIR/custom"

  # Install oh-my-zsh (sans toucher à .zshrc tout de suite : KEEP_ZSHRC=yes)
  if [[ ! -d "$ZSH_DIR" ]]; then
    log "Install oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    ok "oh-my-zsh déjà présent"
  fi

  # Plugins externes (les plus utiles, à cloner manuellement)
  install_zsh_plugin() {
    local name="$1" repo="$2"
    local dest="$ZSH_CUSTOM_DIR/plugins/$name"
    if [[ ! -d "$dest" ]]; then
      git clone --depth=1 "$repo" "$dest" >/dev/null 2>&1 \
        && ok "plugin zsh : $name installé" \
        || warn "plugin zsh : $name a foiré"
    fi
  }
  install_zsh_plugin "zsh-autosuggestions"     "https://github.com/zsh-users/zsh-autosuggestions"
  install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

  # Génération d'un .zshrc propre si absent (oh-my-zsh en pose un par défaut, on vérifie)
  if [[ ! -f "$HOME/.zshrc" ]]; then
    cp "$ZSH_DIR/templates/zshrc.zsh-template" "$HOME/.zshrc"
  fi

  # Configurer le thème + activer les plugins via sed (idempotent)
  sed -i.bak -E "s|^ZSH_THEME=.*|ZSH_THEME=\"$ZSH_THEME_NAME\"|" "$HOME/.zshrc"
  sed -i.bak -E "s|^plugins=\(.*\)|plugins=(git tmux gh rust npm zsh-autosuggestions zsh-syntax-highlighting)|" "$HOME/.zshrc"
  rm -f "$HOME/.zshrc.bak"

  # Définir zsh comme shell par défaut de l'utilisateur (sans demander mdp)
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    log "Définition de zsh comme shell par défaut pour $USER"
    sudo chsh -s "$(which zsh)" "$USER"
  fi
else
  log "11/11  zsh (sauté — passe INSTALL_ZSH=yes pour l'installer)"
fi

# ============================================================
# Shell init (PATH + env) — écrit dans .zshrc ET .bashrc
# ============================================================
SHELL_BLOCK_MARKER="# === tpm-aoe / Claude Code (bootstrap-linux.sh) ==="

write_shell_block() {
  local rc="$1" shell_kind="$2"
  [[ -f "$rc" ]] || touch "$rc"
  if ! grep -qF "$SHELL_BLOCK_MARKER" "$rc" 2>/dev/null; then
    cat >> "$rc" <<EOF

$SHELL_BLOCK_MARKER
export PATH="\$HOME/.cargo/bin:\$PATH"
export PATH="\$HOME/.local/share/fnm:\$PATH"
eval "\$(fnm env --use-on-cd --shell $shell_kind)"
export TPM_WORKFLOW_PATH="$TPM_WORKFLOW_DIR"
EOF
    ok "Bloc env ajouté à $rc"
  fi
}

write_shell_block "$HOME/.bashrc" "bash"
[[ "$INSTALL_ZSH" == "yes" ]] && write_shell_block "$HOME/.zshrc" "zsh"

# ============================================================
log ""
ok "Bootstrap terminé."
log ""
log "Étapes manuelles restantes :"
if [[ "$INSTALL_ZSH" == "yes" ]] && [[ "$SHELL" != "$(which zsh)" ]]; then
  log "  1. Logout/login (ou : exec zsh) pour bénéficier de zsh par défaut"
else
  log "  1. source ~/.bashrc ou source ~/.zshrc  # recharger PATH/env"
fi
log "  2. gh auth login                           # login GitHub CLI (si pas déjà fait)"
log "  3. claude login                            # login Claude Code"
log "  4. cd $AOE_DIR && aoe                      # tester la TUI"
log ""
log "Mises à jour ultérieures :"
log "  cd $AOE_DIR && git pull && cargo build --release --features serve"
log "  cd $TPM_WORKFLOW_DIR && git pull           # le symlink fait que les skills sont updated"
log ""

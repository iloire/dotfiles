# Encryption Options for sync-github.sh

This document outlines three security options for encrypting files before pushing to GitHub with the sync-github.sh script.

## Option 1: **git-crypt** (Transparent Encryption) ⭐ RECOMMENDED

**Best for**: Selective file encryption with minimal workflow disruption

### Overview
- Uses GPG keys or symmetric encryption
- Files are encrypted automatically on commit, decrypted on checkout
- `.gitattributes` specifies which files to encrypt
- Works transparently with git workflow

### Pros
- Transparent integration - no manual encryption/decryption steps
- Integrates seamlessly with git
- Supports team collaboration with GPG
- Selective encryption - only encrypt sensitive files
- Standard git workflow unchanged

### Cons
- Requires git-crypt installation
- Encryption key must be managed separately
- One-time setup per repository

### Environment Variable
```bash
export GITCRYPT_KEY_FILE="$HOME/.config/gitcrypt/key"
```

### Implementation Steps

#### 1. Install git-crypt
```bash
# Ubuntu/Debian
sudo apt-get install git-crypt

# macOS
brew install git-crypt

# Arch Linux
sudo pacman -S git-crypt
```

#### 2. Generate symmetric key
```bash
mkdir -p ~/.config/gitcrypt
dd if=/dev/urandom bs=32 count=1 > ~/.config/gitcrypt/key
chmod 600 ~/.config/gitcrypt/key
```

#### 3. Add to shell configuration
```bash
# Add to ~/.bashrc or ~/.zshrc
export GITCRYPT_KEY_FILE="$HOME/.config/gitcrypt/key"
```

#### 4. Configure repository
```bash
cd /path/to/repo
git-crypt init

# For symmetric key
git-crypt unlock "$GITCRYPT_KEY_FILE"
```

#### 5. Create .gitattributes
```bash
# Create .gitattributes to specify what to encrypt
cat > .gitattributes << 'EOF'
# Encrypt all markdown files
*.md filter=git-crypt diff=git-crypt

# Encrypt environment files
*.env filter=git-crypt diff=git-crypt
.env.* filter=git-crypt diff=git-crypt

# Encrypt sensitive configuration
*secret* filter=git-crypt diff=git-crypt
*credential* filter=git-crypt diff=git-crypt

# Don't encrypt images
*.png !filter !diff
*.jpg !filter !diff
*.jpeg !filter !diff
*.gif !filter !diff
EOF

git add .gitattributes
git commit -m "Add git-crypt encryption configuration"
```

#### 6. Modifications needed in sync-github.sh

Add these functions to the script:

```bash
# Function to setup encryption for a repository
setup_encryption() {
    local DIR="$1"

    if [ -z "$GITCRYPT_KEY_FILE" ]; then
        log_message "GITCRYPT_KEY_FILE not set, skipping encryption setup"
        return 0
    fi

    if [ ! -f "$GITCRYPT_KEY_FILE" ]; then
        error_message "Encryption key file not found: $GITCRYPT_KEY_FILE"
        return 1
    fi

    if ! command -v git-crypt &> /dev/null; then
        error_message "git-crypt not installed"
        return 1
    fi

    cd "$DIR" || return 1

    # Check if git-crypt is already initialized
    if [ ! -f .git/git-crypt/keys/default ]; then
        log_message "Initializing git-crypt for $DIR"
        git-crypt init >> "$LOG_FILE" 2>&1
    fi

    # Unlock with key
    log_message "Unlocking repository with encryption key"
    git-crypt unlock "$GITCRYPT_KEY_FILE" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        log_message "Repository encrypted and unlocked successfully"
        return 0
    else
        error_message "Failed to unlock repository"
        return 1
    fi
}

# Function to unlock repository before operations
unlock_repository() {
    local DIR="$1"

    if [ -z "$GITCRYPT_KEY_FILE" ]; then
        return 0  # Not using encryption
    fi

    if [ ! -f "$GITCRYPT_KEY_FILE" ]; then
        error_message "Encryption key file not found: $GITCRYPT_KEY_FILE"
        return 1
    fi

    cd "$DIR" || return 1

    # Check if repository is encrypted
    if [ -f .git/git-crypt/keys/default ]; then
        log_message "Unlocking encrypted repository"
        git-crypt unlock "$GITCRYPT_KEY_FILE" >> "$LOG_FILE" 2>&1
        return $?
    fi

    return 0
}
```

Add validation at script start:
```bash
# After loading config file, add:
if [ -n "$GITCRYPT_KEY_FILE" ]; then
    if [ ! -f "$GITCRYPT_KEY_FILE" ]; then
        error_message "GITCRYPT_KEY_FILE is set but file doesn't exist: $GITCRYPT_KEY_FILE"
        exit 1
    fi
    if ! command -v git-crypt &> /dev/null; then
        error_message "git-crypt is required but not installed. Install with: sudo apt-get install git-crypt"
        exit 1
    fi
    log_message "Encryption enabled with key: $GITCRYPT_KEY_FILE"
fi
```

Modify `sync_directory()` function:
```bash
# After git init section (line 162), add:
if [ -n "$GITCRYPT_KEY_FILE" ]; then
    setup_encryption "$DIR" || {
        error_message "Failed to setup encryption for $DIR"
        return 1
    }
fi

# Before git pull (line 165), add:
unlock_repository "$DIR" || {
    error_message "Failed to unlock repository $DIR"
    return 1
}
```

---

## Option 2: **GPG Encryption with Pre-commit Hook** (Manual Encryption)

**Best for**: Full control over encryption process without additional tools

### Overview
- Encrypt files with `gpg --symmetric` before committing
- Create `.encrypted/` directory for encrypted versions
- Pre-commit hook automatically encrypts specified file patterns
- Requires manual decryption to read files

### Pros
- Standard tool (GPG) - available everywhere
- No additional dependencies
- Works on any system with GPG
- Complete control over encryption process
- Can use strong custom passphrases

### Cons
- More manual setup required
- Need to track encrypted/unencrypted file pairs
- More complex workflow
- Pre-commit hooks can slow down commits
- Files not transparent - need explicit decryption

### Environment Variable
```bash
export GPG_PASSPHRASE="your-secure-passphrase-here"
```

### Implementation Steps

#### 1. Configure GPG
```bash
# GPG should already be installed on most systems
gpg --version

# If not installed:
# Ubuntu/Debian: sudo apt-get install gnupg
# macOS: brew install gnupg
```

#### 2. Set passphrase in environment
```bash
# Add to ~/.bashrc or ~/.zshrc
export GPG_PASSPHRASE="your-very-secure-passphrase-here"
```

#### 3. Create encryption script
```bash
#!/bin/bash
# encrypt-files.sh

ENCRYPTED_DIR=".encrypted"
mkdir -p "$ENCRYPTED_DIR"

# Patterns to encrypt
PATTERNS=("*.md" "*.txt" "*.env")

for pattern in "${PATTERNS[@]}"; do
    find . -name "$pattern" -type f -not -path "./$ENCRYPTED_DIR/*" -not -path "./.git/*" | while read -r file; do
        encrypted_file="$ENCRYPTED_DIR/${file#./}.gpg"
        mkdir -p "$(dirname "$encrypted_file")"

        echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
            --symmetric --cipher-algo AES256 \
            -o "$encrypted_file" "$file"

        echo "Encrypted: $file -> $encrypted_file"
    done
done
```

#### 4. Create .gitignore
```bash
# Don't commit unencrypted files
*.md
*.txt
*.env
!.encrypted/

# Don't commit images
*.png
*.jpg
*.jpeg
*.gif
```

---

## Option 3: **git-secret** (Asymmetric Team Encryption)

**Best for**: Team environments with multiple collaborators

### Overview
- Uses GPG public key infrastructure
- Each team member's public key can decrypt secrets
- Hides sensitive files, commits encrypted versions
- Designed specifically for storing secrets in git

### Pros
- Perfect for teams with multiple collaborators
- Secure key distribution via GPG
- Similar to git-crypt but simpler for secrets
- Better key management for teams
- Easy to add/remove collaborators

### Cons
- Requires GPG setup for all team members
- Each collaborator needs their key added
- Overkill for single-user scenarios
- Additional tool to install and maintain

### Environment Variable
```bash
export GPG_KEY_ID="your-gpg-key-id"
# or
export GIT_SECRET_GPG_PRIVATE_KEY="/path/to/private/key"
```

### Implementation Steps

#### 1. Install git-secret
```bash
# Ubuntu/Debian
sudo apt-get install git-secret

# macOS
brew install git-secret

# Manual installation
git clone https://github.com/sobolevn/git-secret.git
cd git-secret
make build
PREFIX="/usr/local" make install
```

#### 2. Generate GPG key if needed
```bash
gpg --full-generate-key
# Follow prompts, use RSA 4096-bit key
```

#### 3. Initialize git-secret in repository
```bash
cd /path/to/repo
git secret init
git secret tell your-email@example.com
```

#### 4. Hide files
```bash
# Add files to be encrypted
git secret add sensitive-notes.md
git secret add .env

# Hide (encrypt) all registered files
git secret hide
```

#### 5. Share with team members
```bash
# Add team member's GPG key
gpg --import teammate-public-key.asc
git secret tell teammate@example.com

# Re-encrypt for all users
git secret hide
```

---

## Comparison Table

| Feature | git-crypt | GPG + Hook | git-secret |
|---------|-----------|------------|------------|
| **Setup Complexity** | Low | Medium | Medium |
| **Transparency** | High | Low | Medium |
| **Team Support** | Good | Poor | Excellent |
| **Single User** | Excellent | Good | Fair |
| **Dependencies** | git-crypt | GPG (built-in) | git-secret, GPG |
| **Automation** | Automatic | Semi-manual | Semi-automatic |
| **Selective Encryption** | Excellent | Good | Good |
| **Recovery** | Easy | Medium | Easy |

---

## Security Best Practices

### Key Management
1. **Never commit encryption keys** - add them to `.gitignore`
2. **Use strong passphrases** - minimum 20 characters with mixed case, numbers, symbols
3. **Rotate keys periodically** - every 6-12 months
4. **Backup keys securely** - use password manager or encrypted storage
5. **Use key derivation** - consider using KDF for passphrase-based keys

### Environment Variables
```bash
# Store in shell config (NOT in git)
# ~/.bashrc, ~/.zshrc, or ~/.profile

# git-crypt option
export GITCRYPT_KEY_FILE="$HOME/.config/gitcrypt/key"

# GPG option
export GPG_PASSPHRASE="your-secure-passphrase"

# git-secret option
export GPG_KEY_ID="your-key-id"
```

### Permissions
```bash
# Secure key files
chmod 600 ~/.config/gitcrypt/key
chmod 700 ~/.config/gitcrypt/

# Secure GPG directory
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
```

### Testing
Before committing to encryption:
1. Test encryption/decryption cycle
2. Verify files are actually encrypted in GitHub
3. Test recovery on a different machine
4. Document recovery process for emergencies

---

## Recovery Procedures

### git-crypt Recovery
```bash
# On new machine:
git clone <repo-url>
cd <repo>
git-crypt unlock /path/to/key-file

# Verify decryption
cat sensitive-file.md  # Should be readable
```

### GPG Recovery
```bash
# Decrypt specific file
echo "$GPG_PASSPHRASE" | gpg --batch --passphrase-fd 0 \
    -d .encrypted/file.md.gpg > file.md

# Decrypt all files
find .encrypted -name "*.gpg" | while read f; do
    output="${f%.gpg}"
    output="${output#.encrypted/}"
    echo "$GPG_PASSPHRASE" | gpg --batch --passphrase-fd 0 -d "$f" > "$output"
done
```

### git-secret Recovery
```bash
# On new machine with your GPG key:
git clone <repo-url>
cd <repo>
git secret reveal

# Or reveal with specific key
git secret reveal -p /path/to/private/key
```

---

## Recommendation Summary

**For your use case (single user, markdown/code/images, automated sync):**

### Use **git-crypt** (Option 1) because:
1. ✅ Transparent - no workflow changes after setup
2. ✅ Selective - encrypt only sensitive files
3. ✅ Simple - one-time setup per repo
4. ✅ Automated - works with your sync script
5. ✅ Secure - AES-256 encryption
6. ✅ Fast - minimal performance overhead

### Implementation Priority:
1. Install git-crypt
2. Generate symmetric key
3. Add environment variable
4. Modify sync-github.sh
5. Create .gitattributes in your notes directory
6. Test encryption on sample files

### Quick Start Command:
```bash
# Install git-crypt
sudo apt-get install git-crypt

# Setup key
mkdir -p ~/.config/gitcrypt
dd if=/dev/urandom bs=32 count=1 > ~/.config/gitcrypt/key
chmod 600 ~/.config/gitcrypt/key

# Add to shell
echo 'export GITCRYPT_KEY_FILE="$HOME/.config/gitcrypt/key"' >> ~/.bashrc
source ~/.bashrc

# Initialize in your notes directory
cd /home/ivan/notes
git-crypt init
git-crypt unlock "$GITCRYPT_KEY_FILE"

# Create .gitattributes
cat > .gitattributes << 'EOF'
*.md filter=git-crypt diff=git-crypt
secretfile* filter=git-crypt diff=git-crypt
*.png !filter !diff
*.jpg !filter !diff
EOF

git add .gitattributes
git commit -m "Add encryption for sensitive files"
```

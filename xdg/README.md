# XDG config

Desktop files in `applications/` are deployed to `~/.local/share/applications/`.

## Setup

Run the ansible playbook to symlink all desktop files:

```bash
ansible-playbook ~/code/ansible-recipes/playbooks/linux/xdg-desktop.yml
```

Or create symlinks manually for individual files:

```bash
ln -sf ~/dotfiles/xdg/applications/app.desktop ~/.local/share/applications/app.desktop
```

## Updating AppImages

When updating an AppImage that uses a version-agnostic symlink:

1. Download the new AppImage to `~/apps/`

2. Make it executable:
   ```bash
   chmod +x ~/apps/AppName-X.XX.X-linux-X64.AppImage
   ```

3. Update the symlink:
   ```bash
   ln -sf ~/apps/AppName-X.XX.X-linux-X64.AppImage ~/apps/AppName.AppImage
   ```

4. (Optional) Remove the old AppImage:
   ```bash
   rm ~/apps/AppName-OLD-VERSION.AppImage
   ```

The desktop shortcut will automatically use the new version since it points to the generic symlink.

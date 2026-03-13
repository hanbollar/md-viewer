# md-viewer

A lightweight macOS utility for viewing Markdown files. Open `.md` files directly from Finder's right-click context menu or use it as a standalone app.

## Features

- View Markdown files with rendered formatting
- Right-click context menu integration in Finder
- Standalone app for drag-and-drop viewing

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/hanbollar/md-viewer.git
   cd md-viewer
   ```

2. Build the app (instructions depend on implementation)

3. Move the built app to `/Applications`

### Setting Up Right-Click Context Menu

To add "Open with md-viewer" to Finder's right-click menu:

1. Open **System Settings** > **Privacy & Security** > **Extensions**
2. Enable the md-viewer Finder extension

Or manually:

1. Right-click any `.md` file in Finder
2. Select **Open With** > **Other...**
3. Choose `md-viewer.app`
4. Check "Always Open With" to set as default

## Usage

- **As an app**: Open md-viewer and drag a `.md` file onto the window
- **From Finder**: Right-click a `.md` file > **Open With** > **md-viewer**
- **From Terminal**:
  ```bash
  open -a md-viewer file.md
  ```

## License

MIT License - see [LICENSE](LICENSE) for details.

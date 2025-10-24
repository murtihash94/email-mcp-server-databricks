# Migration Guide: Email MCP Server to Databricks Apps

This document explains the changes made to convert the Email MCP Server to support Databricks Apps deployment.

## What Changed?

The Email MCP Server has been restructured to follow the [Databricks MCP template](https://github.com/murtihash94/custom_mcp_server_databricks) for deployment to Databricks Apps while maintaining backward compatibility.

## New Directory Structure

```
Before:
email-mcp-server/
├── main.py              # Server code
├── pyproject.toml
├── test_email.py
└── README.md

After:
email-mcp-server-databricks/
├── src/
│   └── email_server/
│       ├── __init__.py
│       ├── server.py       # Core MCP server (was main.py)
│       ├── main.py         # Entry point for uvicorn
│       ├── app.py          # FastAPI wrapper for Databricks
│       └── static/
│           └── index.html  # Landing page
├── hooks/
│   └── apps_build.py       # Build hook for Databricks
├── databricks.yml          # Bundle deployment config
├── app.yaml                # Direct deployment config
├── requirements.txt        # Deployment dependencies
├── DEPLOYMENT.md           # Databricks deployment guide
├── main.py                 # Legacy entry point (deprecated)
├── pyproject.toml
├── test_email.py
└── README.md
```

## Breaking Changes

### None for Local Users!

If you're using the MCP server locally with Claude Desktop or Cursor, you can continue to use it exactly as before:

```json
{
  "mcpServers": {
    "email-mcp-server": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/email-mcp-server-databricks",
        "run",
        "main.py"
      ],
      "env": {
        "SMTP_HOST": "smtp.gmail.com",
        ...
      }
    }
  }
}
```

### Recommended Migration for Local Users

Update your configuration to use the new entry point:

```json
{
  "mcpServers": {
    "email-mcp-server": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/email-mcp-server-databricks",
        "run",
        "email-server"
      ],
      "env": {
        "SMTP_HOST": "smtp.gmail.com",
        ...
      }
    }
  }
}
```

The difference:
- Old: `"run", "main.py"` - Runs stdio transport directly
- New: `"run", "email-server"` - Runs via the package entry point

Both work, but the new method is preferred for consistency with Databricks deployment.

## New Features

### 1. Databricks Apps Support

Deploy the MCP server to Databricks Apps for enterprise use:

```bash
# Quick deployment
databricks apps create email-mcp-server
databricks sync . "/Users/$USER/email-mcp-server"
databricks apps deploy email-mcp-server --source-code-path "/Workspace/Users/$USER/email-mcp-server"

# Or using bundles
databricks bundle deploy
databricks bundle run email-mcp-server
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

### 2. Web Interface

When running on Databricks Apps or locally via `uv run email-server`, you get a web landing page at the root URL with:
- Server information
- Available tools
- Connection examples
- Configuration help

### 3. FastAPI Integration

The server now wraps the MCP protocol with FastAPI, enabling:
- Web-based MCP access via Streamable HTTP transport
- Better integration with Databricks authentication
- A landing page for documentation
- Future extensibility for webhooks and other features

### 4. Build System

Automated build process for Databricks Apps:

```bash
uv build --wheel
```

This creates:
- A Python wheel package
- A `.build/` directory with deployment artifacts
- Proper requirements.txt for Databricks

## Configuration Changes

### pyproject.toml

Updated to include:
- FastAPI and uvicorn dependencies
- Build system configuration with hatchling
- Custom build hook for Databricks Apps
- Entry point script: `email-server`

### New Files

- `app.yaml`: Databricks Apps configuration with environment variables
- `databricks.yml`: Databricks bundle configuration
- `requirements.txt`: Deployment dependencies (just `uv`)
- `hooks/apps_build.py`: Custom build hook
- `DEPLOYMENT.md`: Comprehensive deployment guide

## Migration Steps

### For Local Development (Optional)

1. Pull the latest changes
2. Run `uv sync` to update dependencies
3. Update your Claude Desktop config to use `email-server` instead of `main.py`
4. Test: `uv run email-server`

### For Databricks Deployment (New)

Follow the instructions in [DEPLOYMENT.md](DEPLOYMENT.md).

## FAQ

### Q: Do I need to change anything if I'm using it locally?

**A:** No, the old `main.py` still works. But we recommend updating to `email-server` for consistency.

### Q: Can I still use stdio transport?

**A:** Yes! Both methods support stdio transport:
- `python main.py` (legacy)
- `uv run email-server` (new, also supports HTTP)

### Q: What's the difference between the two entry points?

**A:** 
- `main.py`: Runs MCP with stdio transport only
- `email-server`: Runs uvicorn with FastAPI wrapper, supports both stdio and HTTP

### Q: Do I need Databricks to use this?

**A:** No! The server works perfectly fine locally. Databricks support is an additional feature for enterprise deployments.

### Q: How do I test locally before deploying to Databricks?

**A:**
```bash
# Install dependencies
uv sync

# Test the build
uv build --wheel

# Run locally (with web interface)
uv run email-server

# Run tests
uv run python test_email.py
```

### Q: Will you remove the old main.py?

**A:** Not in the foreseeable future. It's kept for backward compatibility. However, it will show a deprecation warning when run directly.

### Q: Can I contribute?

**A:** Yes! This is an open-source project. See the repository for contribution guidelines.

## Support

- For local usage issues: See [README.md](README.md)
- For Databricks deployment: See [DEPLOYMENT.md](DEPLOYMENT.md)
- For bugs or features: Open an issue on GitHub

## Version History

- **v0.1.0** (Current): 
  - Restructured for Databricks Apps
  - Added FastAPI wrapper
  - Added comprehensive deployment documentation
  - Maintained backward compatibility

- **Previous**: 
  - Simple MCP server with stdio transport
  - Local development only

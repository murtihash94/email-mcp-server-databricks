# Quick Reference Guide

## Local Development

```bash
# Install dependencies
uv sync

# Run development server (with hot reload)
uv run email-server
# or
make dev

# Run tests
uv run python test_email.py
# or  
make test

# Build wheel
uv build --wheel
# or
make build
```

## Databricks Deployment

### Option 1: Using databricks apps CLI

```bash
# Configure authentication
export DATABRICKS_CONFIG_PROFILE=your-profile
databricks auth login --profile "$DATABRICKS_CONFIG_PROFILE"

# Edit app.yaml with your SMTP credentials

# Deploy
databricks apps create email-mcp-server
DATABRICKS_USERNAME=$(databricks current-user me | jq -r .userName)
databricks sync . "/Users/$DATABRICKS_USERNAME/email-mcp-server"
databricks apps deploy email-mcp-server --source-code-path "/Workspace/Users/$DATABRICKS_USERNAME/email-mcp-server"

# Or use make
make deploy-apps
```

### Option 2: Using databricks bundle CLI

```bash
# Deploy
databricks bundle deploy
databricks bundle run email-mcp-server

# Or use make
make deploy-bundle
```

## Connecting to Deployed Server

### Get App URL
```bash
databricks apps get email-mcp-server
```

### Get Auth Token
```bash
databricks auth token
```

### Python Client Example
```python
from databricks.sdk import WorkspaceClient
from databricks_mcp import DatabricksOAuthClientProvider
from mcp.client.streamable_http import streamablehttp_client as connect
from mcp import ClientSession

client = WorkspaceClient()

async def main():
    app_url = "https://your-app-url.databricksapps.com/mcp/"
    async with connect(app_url, auth=DatabricksOAuthClientProvider(client)) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool("send_email", {
                "to": "recipient@example.com",
                "subject": "Test",
                "body": "Hello!",
                "is_html": False
            })
```

## Common Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make install` | Install dependencies |
| `make build` | Build wheel package |
| `make test` | Run tests |
| `make clean` | Clean build artifacts |
| `make dev` | Start dev server |
| `make deploy-bundle` | Deploy via bundle CLI |
| `make deploy-apps` | Deploy via apps CLI |

## SMTP Configuration

### Gmail
```yaml
SMTP_HOST: smtp.gmail.com
SMTP_PORT: "587"
SMTP_SECURE: "false"
SMTP_USER: your-email@gmail.com
SMTP_FROM: your-email@gmail.com
SMTP_PASS: your-app-password
```

**Setup**: Enable 2FA → Google Account → Security → App passwords → Generate for "Mail"

### Outlook
```yaml
SMTP_HOST: smtp-mail.outlook.com
SMTP_PORT: "587"
SMTP_SECURE: "false"
SMTP_USER: your-email@outlook.com
SMTP_FROM: your-email@outlook.com
SMTP_PASS: your-password
```

## Available Tools

1. **send_email**: Simple email sending with environment config
2. **send_custom_email**: Advanced email with CC/BCC/attachments
3. **test_smtp_connection_tool**: Test SMTP connection

## File Structure

```
├── src/email_server/     # Main package
│   ├── server.py         # Core MCP logic
│   ├── app.py            # FastAPI wrapper
│   ├── main.py           # Entry point
│   └── static/           # Web assets
├── hooks/                # Build hooks
├── app.yaml              # Databricks Apps config
├── databricks.yml        # Bundle config
├── DEPLOYMENT.md         # Full deployment guide
├── MIGRATION.md          # Migration guide
└── README.md             # Main documentation

## Troubleshooting

### Build Issues
```bash
make clean
make build
```

### App Not Starting
```bash
databricks apps get email-mcp-server
databricks apps logs email-mcp-server
```

### Import Errors
```bash
uv sync
```

### Test Email
```bash
uv run python test_email.py
```

## Getting Help

- **README.md**: Complete usage guide
- **DEPLOYMENT.md**: Databricks deployment instructions
- **MIGRATION.md**: Migration from old version
- **GitHub Issues**: Bug reports and feature requests

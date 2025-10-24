# Deploying Email MCP Server to Databricks Apps

This guide provides step-by-step instructions for deploying the Email MCP Server to Databricks Apps.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Configuration](#configuration)
3. [Deployment Methods](#deployment-methods)
   - [Method 1: Using databricks apps CLI](#method-1-using-databricks-apps-cli)
   - [Method 2: Using databricks bundle CLI](#method-2-using-databricks-bundle-cli)
4. [Connecting to the Deployed Server](#connecting-to-the-deployed-server)
5. [Troubleshooting](#troubleshooting)
6. [Updating the Deployment](#updating-the-deployment)

## Prerequisites

### Required Software

1. **Databricks CLI** - Install from https://docs.databricks.com/dev-tools/cli/
   ```bash
   # macOS/Linux
   curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
   
   # Or via pip
   pip install databricks-cli
   ```

2. **uv Package Manager** - Install from https://docs.astral.sh/uv/
   ```bash
   # macOS/Linux
   curl -LsSf https://astral.sh/uv/install.sh | sh
   
   # Or via pip
   pip install uv
   ```

3. **jq** (optional, for parsing JSON) - Install from https://stedolan.github.io/jq/
   ```bash
   # macOS
   brew install jq
   
   # Linux
   sudo apt-get install jq
   ```

### Required Access

- Databricks workspace with Apps support
- Appropriate permissions to create and deploy apps
- SMTP server credentials (Gmail, Outlook, or other provider)

## Configuration

### 1. Configure Databricks Authentication

Set up authentication with your Databricks workspace:

```bash
# Set your profile name
export DATABRICKS_CONFIG_PROFILE=email-mcp-server

# Login to Databricks
databricks auth login --profile "$DATABRICKS_CONFIG_PROFILE"
```

Follow the prompts to authenticate via OAuth or provide your workspace URL and token.

### 2. Configure SMTP Settings

Edit the `app.yaml` file in the project root to set your SMTP credentials:

```yaml
command: ["uv", "run", "email-server"]
env:
  - name: SMTP_HOST
    value: smtp.gmail.com              # Your SMTP server
  - name: SMTP_PORT
    value: "587"                       # SMTP port (587 for TLS, 465 for SSL)
  - name: SMTP_SECURE
    value: "false"                     # "true" for SSL (port 465), "false" for TLS (port 587)
  - name: SMTP_USER
    value: your-email@gmail.com        # Your email address
  - name: SMTP_FROM
    value: your-email@gmail.com        # Sender email address
  - name: SMTP_PASS
    value: your-app-password           # Your email password or app password
```

**Important Security Notes:**
- For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833), not your regular password
- Never commit real credentials to version control
- Consider using Databricks Secrets for production deployments

### 3. Build the Project

Build the wheel package before deployment:

```bash
cd email-mcp-server-databricks
uv build --wheel
```

This creates:
- `dist/email_server-0.1.0-py3-none-any.whl` - The Python wheel
- `.build/` directory - Databricks Apps-compatible build artifacts

## Deployment Methods

Choose one of the two deployment methods below.

### Method 1: Using `databricks apps` CLI

This is the simpler approach, ideal for quick deployments and testing.

#### Step 1: Create the App

```bash
databricks apps create email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

#### Step 2: Upload and Deploy

```bash
# Get your Databricks username
DATABRICKS_USERNAME=$(databricks current-user me -p "$DATABRICKS_CONFIG_PROFILE" | jq -r .userName)

# Upload the source code
databricks sync . "/Users/$DATABRICKS_USERNAME/email-mcp-server" -p "$DATABRICKS_CONFIG_PROFILE"

# Deploy the app
databricks apps deploy email-mcp-server \
  --source-code-path "/Workspace/Users/$DATABRICKS_USERNAME/email-mcp-server" \
  -p "$DATABRICKS_CONFIG_PROFILE"
```

#### Step 3: Start the App (if not auto-started)

```bash
databricks apps start email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

### Method 2: Using `databricks bundle` CLI

This approach is better for version control, team deployments, and CI/CD pipelines.

#### Step 1: Review Bundle Configuration

The `databricks.yml` file in the project root defines the bundle configuration:

```yaml
bundle:
  name: email-mcp-server

sync:
  include:
    - .build

artifacts:
  default:
    type: whl
    path: .
    build: uv build --wheel

resources:
  apps:
    email-mcp-server:
      name: "email-mcp-server-${bundle.target}"
      description: "Email MCP Server on Databricks Apps"
      source_code_path: ./.build

targets:
  dev:
    mode: development
    default: true
```

#### Step 2: Deploy with Bundle

```bash
# Deploy the bundle (builds and uploads artifacts)
databricks bundle deploy -p "$DATABRICKS_CONFIG_PROFILE"

# Run the app deployment
databricks bundle run email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

For production deployments, you can create additional targets:

```bash
# Deploy to production target
databricks bundle deploy -t prod -p "$DATABRICKS_CONFIG_PROFILE"
```

## Connecting to the Deployed Server

### Get Your App URL

```bash
databricks apps get email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

Look for the `url` field in the output. It typically looks like:
```
https://your-workspace.cloud.databricks.com/apps/email-mcp-server
```

Or with custom domains:
```
https://your-app-name.your-workspace.databricksapps.com
```

### Get Authentication Token

```bash
databricks auth token -p "$DATABRICKS_CONFIG_PROFILE"
```

### Connection Methods

#### 1. Via Python Client

```python
from databricks.sdk import WorkspaceClient
from databricks_mcp import DatabricksOAuthClientProvider
from mcp.client.streamable_http import streamablehttp_client as connect
from mcp import ClientSession

client = WorkspaceClient()

async def main():
    # Replace with your actual app URL
    app_url = "https://your-app-url.databricksapps.com/mcp/"
    
    async with connect(app_url, auth=DatabricksOAuthClientProvider(client)) as (
        read_stream,
        write_stream,
        _,
    ):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            
            # List available tools
            tools = await session.list_tools()
            print(f"Available tools: {tools}")
            
            # Send an email
            result = await session.call_tool(
                "send_email",
                {
                    "to": "recipient@example.com",
                    "subject": "Test from Databricks",
                    "body": "This is a test email sent from Databricks Apps!",
                    "is_html": False
                }
            )
            print(f"Result: {result}")

# Run the async function
import asyncio
asyncio.run(main())
```

#### 2. Via Claude Desktop

Add to your Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "email-databricks": {
      "url": "https://your-app-url.databricksapps.com/mcp/",
      "transport": "streamable-http",
      "headers": {
        "Authorization": "Bearer YOUR_DATABRICKS_TOKEN"
      }
    }
  }
}
```

**Note:** Replace `YOUR_DATABRICKS_TOKEN` with the token from `databricks auth token`.

#### 3. Via MCP Inspector

Use the MCP Inspector tool for testing:

```bash
npx @modelcontextprotocol/inspector \
  --transport streamable-http \
  --url "https://your-app-url.databricksapps.com/mcp/" \
  --header "Authorization: Bearer YOUR_DATABRICKS_TOKEN"
```

### Important Notes

- The URL must end with `/mcp/` (including the trailing slash)
- The app may take a few minutes to start after deployment
- Check app logs if you encounter connection issues

## Troubleshooting

### Check App Status

```bash
databricks apps get email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

Look for the `status` field. Common statuses:
- `RUNNING` - App is active and ready
- `STARTING` - App is starting up
- `STOPPED` - App is stopped
- `ERROR` - App encountered an error

### View App Logs

```bash
databricks apps logs email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

### Common Issues

#### 1. "App not found"

- Verify the app name matches what you created
- Check you're using the correct profile

#### 2. "Authentication failed" when sending emails

- Verify SMTP credentials in `app.yaml`
- For Gmail, ensure you're using an App Password
- Check that 2FA is enabled for Gmail accounts

#### 3. "Connection timeout"

- Verify the app is in `RUNNING` status
- Check that the URL ends with `/mcp/`
- Ensure your Databricks workspace allows app access

#### 4. Build failures

```bash
# Clean and rebuild
rm -rf dist/ .build/
uv build --wheel
```

#### 5. "Module not found" errors

- Ensure all dependencies are in `pyproject.toml`
- Try resyncing dependencies: `uv sync`
- Verify the wheel was built correctly

### Redeploy After Changes

```bash
# Method 1: Using apps CLI
uv build --wheel
databricks sync . "/Users/$DATABRICKS_USERNAME/email-mcp-server" -p "$DATABRICKS_CONFIG_PROFILE"
databricks apps deploy email-mcp-server \
  --source-code-path "/Workspace/Users/$DATABRICKS_USERNAME/email-mcp-server" \
  -p "$DATABRICKS_CONFIG_PROFILE"

# Method 2: Using bundle CLI
databricks bundle deploy -p "$DATABRICKS_CONFIG_PROFILE"
databricks bundle run email-mcp-server -p "$DATABRICKS_CONFIG_PROFILE"
```

## Updating the Deployment

### Update SMTP Configuration

1. Edit `app.yaml` with new SMTP settings
2. Redeploy using one of the methods above

### Update Code

1. Make your code changes
2. Rebuild: `uv build --wheel`
3. Redeploy using one of the methods above

### Environment Variables at Runtime

For production, consider using Databricks Secrets instead of hardcoding in `app.yaml`:

```yaml
command: ["uv", "run", "email-server"]
env:
  - name: SMTP_HOST
    valueFrom:
      secretKeyRef:
        scope: email-server-secrets
        key: smtp-host
  - name: SMTP_USER
    valueFrom:
      secretKeyRef:
        scope: email-server-secrets
        key: smtp-user
  # ... etc
```

Create secrets:
```bash
databricks secrets create-scope email-server-secrets -p "$DATABRICKS_CONFIG_PROFILE"
databricks secrets put-secret email-server-secrets smtp-host -p "$DATABRICKS_CONFIG_PROFILE"
# Follow prompts to enter value
```

## Production Best Practices

1. **Use Secrets**: Store SMTP credentials in Databricks Secrets, not in `app.yaml`
2. **Version Control**: Use bundle deployments with proper Git tags
3. **Multiple Targets**: Define separate `dev`, `staging`, and `prod` targets in `databricks.yml`
4. **Monitoring**: Set up alerts for app health and email sending failures
5. **Rate Limiting**: Implement rate limiting to prevent abuse
6. **Error Handling**: Monitor logs for SMTP errors and authentication issues
7. **Testing**: Test with a development email account before production deployment

## Next Steps

- Review the main [README.md](README.md) for usage examples
- Check the [Databricks Apps documentation](https://docs.databricks.com/en/apps/index.html)
- Explore the [Model Context Protocol specification](https://modelcontextprotocol.io/)

## Support

For issues specific to this MCP server, please open an issue on the GitHub repository.

For Databricks Apps support, consult the [official documentation](https://docs.databricks.com/en/apps/index.html) or contact Databricks support.

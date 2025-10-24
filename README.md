# Email MCP Server

This MCP (Model Context Protocol) server lets your AI assistant send emails for you. It can be deployed locally or on Databricks Apps.

## What Can It Do?

Your AI assistant can:

- Send both plain text and HTML emails
- Attach files and documents
- Send to multiple people with CC/BCC
- Check if your email setup works

## Available Tools

### `send_email` - Simple Email Sending
Send emails quickly using your environment configuration:
- Just specify recipient, subject, and body
- Automatically uses your configured SMTP settings
- Perfect for quick messages

### `send_custom_email` - Advanced Email Features
Send emails with full control:
- Send to multiple people with CC/BCC
- Add file attachments
- Use HTML formatting
- Override SMTP settings per email

### `test_smtp_connection_tool` - Check Setup
Test your email settings before sending important emails.

## Local Development

### Prerequisites

- Python 3.11 or higher
- `uv` package manager

### 1. Install uv

```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or via pip
pip install uv

# Restart your terminal or run:
source ~/.bashrc
```

### 2. Install Project Dependencies

```bash
cd email-mcp-server-databricks
uv sync
```

### 3. Test the Installation

```bash
# Test your email setup
uv run python test_email.py

# Run the server directly (for testing)
uv run email-server
```

### 4. Configure for Local Use with Claude Desktop or Cursor

Add this to your Claude Desktop configuration or Cursor file:
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
              "SMTP_PORT": "587",
              "SMTP_SECURE": "false",
              "SMTP_USER": "your-email@gmail.com",
              "SMTP_FROM": "your-email@gmail.com",
              "SMTP_PASS": "your-app-password"
          }
      }
  }
}
```

**Important**: Change the directory path to match your actual installation location.

## Deploying to Databricks Apps

This MCP server can be deployed to Databricks Apps for enterprise use. Follow the template from the [Databricks MCP repository](https://github.com/databrickslabs/mcp).

### Prerequisites

- Databricks CLI installed and configured
- Databricks workspace access
- `uv` package manager installed

### Option 1: Using `databricks apps` CLI

This is the simpler approach for quick deployments.

#### Step 1: Configure Authentication

```bash
export DATABRICKS_CONFIG_PROFILE=<your-profile-name>
databricks auth login --profile "$DATABRICKS_CONFIG_PROFILE"
```

#### Step 2: Update app.yaml Configuration

Edit `app.yaml` in the root directory to set your SMTP credentials:

```yaml
command: ["uv", "run", "email-server"]
env:
  - name: SMTP_HOST
    value: smtp.gmail.com
  - name: SMTP_PORT
    value: "587"
  - name: SMTP_SECURE
    value: "false"
  - name: SMTP_USER
    value: your-email@gmail.com
  - name: SMTP_FROM
    value: your-email@gmail.com
  - name: SMTP_PASS
    value: your-app-password
```

#### Step 3: Create and Deploy the App

```bash
# Create a Databricks app
databricks apps create email-mcp-server

# Upload the source code and deploy
DATABRICKS_USERNAME=$(databricks current-user me | jq -r .userName)
databricks sync . "/Users/$DATABRICKS_USERNAME/email-mcp-server"
databricks apps deploy email-mcp-server --source-code-path "/Workspace/Users/$DATABRICKS_USERNAME/email-mcp-server"
```

### Option 2: Using `databricks bundle` CLI

This approach is better for version control and team deployments.

#### Step 1: Build the Wheel

```bash
uv build --wheel
```

#### Step 2: Deploy with Bundle

```bash
databricks bundle deploy -p <your-profile-name>
databricks bundle run email-mcp-server -p <your-profile-name>
```

**Note**: Make sure to update the `app.yaml` file with your SMTP credentials before deploying.

### Connecting to the Deployed Server

After deployment, you can connect to the server using the `Streamable HTTP` transport.

#### Get Your App URL

```bash
databricks apps get email-mcp-server -p <your-profile-name>
```

The URL will typically look like:
```
https://your-workspace.cloud.databricks.com/apps/email-mcp-server
```

#### Connect via Python

```python
from databricks.sdk import WorkspaceClient
from databricks_mcp import DatabricksOAuthClientProvider
from mcp.client.streamable_http import streamablehttp_client as connect
from mcp import ClientSession

client = WorkspaceClient()

async def main():
    # Connect to the email MCP server
    app_url = "https://your-app-url.databricksapps.com/mcp/"
    async with connect(app_url, auth=DatabricksOAuthClientProvider(client)) as (
        read_stream,
        write_stream,
        _,
    ):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            # Send an email
            tool_result = await session.call_tool(
                "send_email", 
                {
                    "to": "recipient@example.com",
                    "subject": "Test Email",
                    "body": "Hello from Databricks!",
                    "is_html": False
                }
            )
```

#### Connect via Claude Desktop or MCP Inspector

Use the `Streamable HTTP` transport with:
- **URL**: `https://your-app-url.databricksapps.com/mcp/` (note the trailing `/mcp/`)
- **Authentication**: Bearer token from `databricks auth token -p <your-profile-name>`

**Important**: The URL must end with `/mcp/` (including the trailing slash).

## Usage Examples

### Simple Examples

**Send a basic email:**
```
"Send an email to john@company.com saying the meeting is tomorrow at 2 PM"
```

**Send with HTML formatting:**
```
"Send an HTML email to team@company.com with subject 'Weekly Update' and create a nice formatted message about this week's progress"
```

**Test your setup:**
```
"Test the email connection to make sure it's working"
```

### Advanced Examples

**Send to multiple people with attachments:**
```
"Send a custom email to the team about the project update. Send to team@company.com, CC manager@company.com, and attach the project report"
```

## Email Provider Setup

### For Gmail
```yaml
env:
  - name: SMTP_HOST
    value: smtp.gmail.com
  - name: SMTP_PORT
    value: "587"
  - name: SMTP_SECURE
    value: "false"
  - name: SMTP_USER
    value: your-email@gmail.com
  - name: SMTP_FROM
    value: your-email@gmail.com
  - name: SMTP_PASS
    value: your-app-password
```

**Gmail Setup Steps:**
1. Enable 2-Factor Authentication
2. Go to Google Account → Security → App passwords
3. Generate an app password for "Mail"
4. Use the 16-character app password

### For Outlook
```yaml
env:
  - name: SMTP_HOST
    value: smtp-mail.outlook.com
  - name: SMTP_PORT
    value: "587"
  - name: SMTP_SECURE
    value: "false"
  - name: SMTP_USER
    value: your-email@outlook.com
  - name: SMTP_FROM
    value: your-email@outlook.com
  - name: SMTP_PASS
    value: your-password
```

### For Other Providers
Replace the SMTP settings with your provider's details. Most providers use:
- Port 587 with SMTP_SECURE=false (STARTTLS)
- Port 465 with SMTP_SECURE=true (SSL)

## Configuration Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SMTP_HOST` | Your email server | `smtp.gmail.com` |
| `SMTP_PORT` | Server port | `587` |
| `SMTP_SECURE` | Use SSL (true/false) | `false` |
| `SMTP_USER` | Your username | `user@gmail.com` |
| `SMTP_FROM` | Sender address | `noreply@company.com` |
| `SMTP_PASS` | Your password | `your-password` |

## Troubleshooting

### "Missing Configuration"
- Make sure all environment variables are set in the app.yaml or Claude Desktop config
- Check that the directory path is correct and absolute
- Restart Claude Desktop or redeploy the app after making changes

### "Authentication Failed"
- For Gmail/Yahoo: Use app passwords, not regular passwords
- Enable 2-Factor Authentication first
- Double-check username and password

### "Connection Issues"
- Verify SMTP host and port are correct
- Check your internet connection
- Some networks block SMTP ports

### "Server Not Found"
- Make sure `uv` is installed and in your PATH
- Check that the directory path exists
- Verify the project dependencies are installed with `uv sync`

## Project Structure

```
email-mcp-server-databricks/
├── src/
│   └── email_server/
│       ├── __init__.py
│       ├── server.py          # Core MCP server logic
│       ├── main.py            # Local development entry point
│       ├── app.py             # Databricks Apps FastAPI integration
│       └── static/
│           └── index.html     # Landing page
├── hooks/
│   └── apps_build.py          # Databricks Apps build hook
├── databricks.yml             # Databricks bundle configuration
├── app.yaml                   # Databricks Apps deployment config
├── pyproject.toml             # Project dependencies and metadata
├── requirements.txt           # Deployment requirements
└── README.md                  # This file
```

## Testing

```bash
# Test configuration and connection
uv run python test_email.py

# Send a real test email to yourself
uv run python test_email.py --send-real
```

## License

MIT License - Feel free to use and modify as needed.

from pathlib import Path
from email_server.server import mcp
from fastapi import FastAPI
from fastapi.responses import FileResponse

STATIC_DIR = Path(__file__).parent / "static"

# Create the streamable HTTP app from the MCP server
mcp_app = mcp.streamable_http_app()

# Create the main FastAPI app
app = FastAPI(
    lifespan=lambda _: mcp.session_manager.run(),
    title="Email MCP Server on Databricks Apps",
    description="A Model Context Protocol server for sending emails, deployed on Databricks Apps",
)


@app.get("/", include_in_schema=False)
async def serve_index():
    """Serve the landing page."""
    return FileResponse(STATIC_DIR / "index.html")


# Mount the MCP app at the root
app.mount("/", mcp_app)

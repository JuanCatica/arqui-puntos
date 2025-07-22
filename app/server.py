import os
import boto3
import uvicorn
from mcp.server.fastmcp import FastMCP
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Mount, Route
from mcp.server.sse import SseServerTransport
import logging

# Initialize DynamoDB client (ensure your AWS credentials are set up)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("arquipuntos")
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table_name = os.environ["DYNAMODB_TABLE_NAME"]

# Create the MCP server
mcp = FastMCP("DynamoDB MCP Server")

# Create SSE transport
sse = SseServerTransport(f'/messages/')

# MCP Tool: Store a value in DynamoDB
@mcp.tool()
def add_point(architect: str, date: str, points: int, note: str = None) -> str:
    """
    Records a new points entry for an architect in the DynamoDB table.

    This function validates the required input fields and logs a points transaction for a specified architect on a given date. Each entry includes the architect's identifier, the date, the number of points awarded, and optional fields for a note and the requester's identity. This enables transparent tracking and auditing of point allocations within the system.

    Parameters:
        architect (str): Unique identifier or name of the architect (required).
        date (str): Date of the points entry in ISO 8601 format (required).
        points (int): Number of points to assign (required).
        note (str, optional): Additional context or comments.
    
    Example calling the tool:
        add_point(
            architect = "jcatica",
            date = "2025-07-21",
            points = 3,
            note= "because he is a nice guy"
        )

    Returns:
        str: A formatted summary of the stored record, including all provided details.
    """
    logger.info(input)

    assert architect is not None, "architect must be a non-null string"
    assert date is not None, "date must be a non-null string"
    assert points is not None, "points must be a non-null integer"

    msn = f"""
Architect: {architect}
Date: {date}
Points: {points}
Note: {note}
"""

    table = dynamodb.Table(table_name)
    table.put_item(Item={
        'architect': architect,
        'date': date,
        'points': points,
        'note': note,
    })
    return msn

# MCP SSE handler function
async def handle_sse(request):
    async with sse.connect_sse(request.scope, request.receive, request._send) as (
        read_stream,
        write_stream,
    ):
        await mcp._mcp_server.run(
            read_stream, write_stream, mcp._mcp_server.create_initialization_options()
        )

# Add a health check route handler
async def health_check(request):
    return JSONResponse({'status': 'healthy', 'service': 'arquipuntos'})

if __name__ == '__main__':

    # Create a custom Starlette app that includes our health check
    # AND properly integrates with the MCP SSE implementation
    sse_app = mcp.sse_app()

    # Starlette app
    app = Starlette(
        debug=True,
        routes=[
            Route('/', health_check),
            Route('/sse', endpoint=handle_sse),
            Mount('/messages/', app=sse.handle_post_message),
        ]
    )

    # Start uvicorn
    uvicorn.run(
        app,
        host='0.0.0.0',
        port=8080,
        timeout_graceful_shutdown=2,  # Only wait 2 seconds for connections to close
    )
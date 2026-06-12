import json
import os
import sys

# Ensure backend directory is in sys.path so we can import from app
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
backend_path = os.path.join(project_root, 'backend')
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

from fastapi.openapi.utils import get_openapi
from app.main import app

def export_openapi():
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        openapi_version=app.openapi_version,
        description=app.description,
        routes=app.routes,
    )
    
    frontend_path = os.path.join(project_root, 'frontend', 'openapi.json')
    
    with open(frontend_path, 'w', encoding='utf-8') as f:
        json.dump(openapi_schema, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Successfully exported OpenAPI schema to {frontend_path}")

if __name__ == "__main__":
    export_openapi()

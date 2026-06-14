import json
import os
import sys

# Ensure backend directory is in sys.path so we can import from app
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
backend_path = os.path.join(project_root, 'backend')
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

from app.main import app

def export_openapi() -> None:
    openapi_schema = app.openapi()
    frontend_path = os.path.join(project_root, "frontend", "openapi.json")

    with open(frontend_path, "w", encoding="utf-8", newline="\n") as file:
        json.dump(
            openapi_schema,
            file,
            indent=2,
            ensure_ascii=False,
            sort_keys=True,
        )
        file.write("\n")

    print(f"Successfully exported OpenAPI schema to {frontend_path}")

if __name__ == "__main__":
    export_openapi()


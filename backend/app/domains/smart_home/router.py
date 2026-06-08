"""Smart home API router."""

from __future__ import annotations

import asyncio
import json
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audit import log_audit_from_request
from app.core.permissions import require_permission
from app.database import AsyncSessionLocal, get_db
from app.domains.smart_home import service
from app.domains.smart_home.crypto import (
    SmartHomeCryptoError,
    SmartHomeSecretKeyInvalidError,
    SmartHomeSecretKeyMissingError,
    SmartHomeTokenDecryptError,
)
from app.domains.smart_home.state_stream import smart_home_state_broker
from app.models.user import User
from app.schemas.smart_home import (
    SmartHomeConfigResponse,
    SmartHomeConfigTestRequest,
    SmartHomeConfigTestResponse,
    SmartHomeConfigUpdate,
    SmartHomeEntityListResponse,
    SmartHomeServiceRequest,
    SmartHomeServiceResponse,
)

router = APIRouter(prefix="/smart-home", tags=["smart-home"])


def _http_error(exc: Exception) -> HTTPException:
    if isinstance(exc, service.SmartHomeConfigMissingError):
        return HTTPException(status_code=404, detail="Home Assistant config is not set")
    if isinstance(exc, service.SmartHomeUnsupportedEntityError):
        return HTTPException(status_code=400, detail="Unsupported smart home entity")
    if isinstance(exc, service.SmartHomeUnsupportedServiceError):
        return HTTPException(status_code=400, detail="Unsupported smart home service")
    if isinstance(exc, SmartHomeSecretKeyMissingError):
        return HTTPException(
            status_code=500,
            detail="SMART_HOME_SECRET_KEY is not configured on the server",
        )
    if isinstance(exc, SmartHomeSecretKeyInvalidError):
        return HTTPException(
            status_code=500,
            detail="SMART_HOME_SECRET_KEY is not a valid Fernet key",
        )
    if isinstance(exc, SmartHomeTokenDecryptError):
        return HTTPException(
            status_code=500,
            detail=str(exc),
        )
    if isinstance(exc, SmartHomeCryptoError):
        return HTTPException(status_code=500, detail="Smart home encryption error")
    return HTTPException(status_code=502, detail=str(exc))


@router.get("/config", response_model=SmartHomeConfigResponse)
async def get_config(
    current_user: User = Depends(require_permission("smart_home:configure")),
    db: AsyncSession = Depends(get_db),
):
    try:
        config = await service.get_config(db)
    except Exception as exc:
        raise _http_error(exc) from exc
    response = SmartHomeConfigResponse.model_validate(config)
    response.token_configured = bool(config.encrypted_token)
    return response


@router.put("/config", response_model=SmartHomeConfigResponse)
async def update_config(
    data: SmartHomeConfigUpdate,
    request: Request,
    current_user: User = Depends(require_permission("smart_home:configure")),
    db: AsyncSession = Depends(get_db),
):
    try:
        config = await service.save_config(db, data=data)
    except Exception as exc:
        raise _http_error(exc) from exc
    await log_audit_from_request(
        request,
        db,
        action="smart_home.config.update",
        actor_user_id=current_user.id,
        target_type="smart_home_config",
        target_id=config.id,
        details={"base_url": str(data.base_url), "token": data.token},
        commit=True,
    )
    response = SmartHomeConfigResponse.model_validate(config)
    response.token_configured = bool(config.encrypted_token)
    return response


@router.post("/config/test", response_model=SmartHomeConfigTestResponse)
async def test_config(
    data: SmartHomeConfigTestRequest,
    current_user: User = Depends(require_permission("smart_home:configure")),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await service.test_config(
            db,
            base_url=str(data.base_url).rstrip("/") if data.base_url else None,
            token=data.token,
        )
    except Exception as exc:
        raise _http_error(exc) from exc


@router.get("/entities", response_model=SmartHomeEntityListResponse)
async def list_entities(
    current_user: User = Depends(require_permission("smart_home:read")),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await service.list_entities(db)
    except Exception as exc:
        raise _http_error(exc) from exc


@router.post("/entities/{entity_id}/service", response_model=SmartHomeServiceResponse)
async def call_service(
    entity_id: str,
    data: SmartHomeServiceRequest,
    request: Request,
    current_user: User = Depends(require_permission("smart_home:control")),
    db: AsyncSession = Depends(get_db),
):
    try:
        await service.call_entity_service(
            db,
            entity_id=entity_id,
            service=data.service,
            service_data=data.service_data,
        )
    except Exception as exc:
        raise _http_error(exc) from exc
    await log_audit_from_request(
        request,
        db,
        action="smart_home.entity.control",
        actor_user_id=current_user.id,
        target_type="smart_home_entity",
        target_id=None,
        details={"entity_id": entity_id, "service": data.service},
        commit=True,
    )
    return SmartHomeServiceResponse(
        ok=True, entity_id=entity_id, service=data.service, message="Service call sent"
    )


@router.get("/entities/stream")
async def stream_entities(
    request: Request,
    current_user: User = Depends(require_permission("smart_home:read")),
):
    async def event_generator():
        queue = None
        client = None
        try:
            async with AsyncSessionLocal() as db:
                config = await service.get_config(db)
            client = service._client(config)
            queue = await smart_home_state_broker.subscribe(client)
            yield ": connected\n\n"
            while True:
                if await request.is_disconnected():
                    break
                try:
                    event = await asyncio.wait_for(queue.get(), timeout=15)
                except TimeoutError:
                    yield ": keep-alive\n\n"
                    continue
                raw_state: dict[str, Any] | None = event.get("data", {}).get(
                    "new_state"
                )
                if not raw_state:
                    continue
                entity = service.normalize_entity(raw_state)
                if entity is None:
                    continue
                yield f"data: {json.dumps(entity.model_dump(mode='json'), ensure_ascii=False)}\n\n"
        except Exception as exc:
            yield f"event: error\ndata: {json.dumps({'message': str(exc)}, ensure_ascii=False)}\n\n"
            while not await request.is_disconnected():
                await asyncio.sleep(15)
                yield ": keep-alive\n\n"
        finally:
            if queue is not None:
                await smart_home_state_broker.unsubscribe(queue)
            if client is not None:
                await client.aclose()

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )

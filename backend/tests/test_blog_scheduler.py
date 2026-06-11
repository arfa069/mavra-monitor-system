import pytest


@pytest.mark.asyncio
async def test_publish_due_blog_posts_job_uses_database_session(monkeypatch):
    from app import main

    calls = []

    class SessionContext:
        async def __aenter__(self):
            return "db-session"

        async def __aexit__(self, exc_type, exc, tb):
            return None

    async def publish_due_posts(db):
        calls.append(db)
        return 2

    monkeypatch.setattr("app.database.AsyncSessionLocal", lambda: SessionContext())
    monkeypatch.setattr("app.domains.blog.service.publish_due_posts", publish_due_posts)

    published = await main.publish_due_blog_posts_job()

    assert published == 2
    assert calls == ["db-session"]

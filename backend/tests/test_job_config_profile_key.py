import pytest


def test_job_search_config_model_has_profile_key_column():
    from app.models.job import JobSearchConfig

    column = JobSearchConfig.__table__.columns["profile_key"]

    assert column.default.arg == "default"
    assert column.nullable is False
    assert column.type.length == 80


def test_job_config_create_defaults_profile_key():
    from app.schemas.job import JobSearchConfigCreate

    payload = JobSearchConfigCreate(
        name="Boss",
        platform="boss",
        url="https://www.zhipin.com/web/geek/job?query=python",
    )

    assert payload.profile_key == "default"


def test_job_config_rejects_path_traversal_profile_key():
    from pydantic import ValidationError
    from app.schemas.job import JobSearchConfigCreate

    with pytest.raises(ValidationError):
        JobSearchConfigCreate(
            name="Bad",
            platform="boss",
            url="https://www.zhipin.com/web/geek/job?query=python",
            profile_key="../default",
        )

from types import SimpleNamespace


def test_group_job_configs_by_platform_and_profile():
    from app.domains.jobs.crawl_service import _group_job_configs_for_profile_leases

    configs = [
        SimpleNamespace(id=1, platform="boss", profile_key="job-a"),
        SimpleNamespace(id=2, platform="boss", profile_key="job-b"),
        SimpleNamespace(id=3, platform="51job", profile_key="job-a"),
        SimpleNamespace(id=4, platform="liepin", profile_key=None),
    ]

    groups = _group_job_configs_for_profile_leases(configs)

    assert list(groups.keys()) == [
        ("boss", "job-a"),
        ("boss", "job-b"),
        ("51job", "job-a"),
        ("liepin", "default"),
    ]
    assert [config.id for config in groups[("boss", "job-a")]] == [1]


def test_job_group_task_metadata():
    from app.domains.jobs.crawl_service import _job_group_task_metadata

    metadata = _job_group_task_metadata("boss", "job-a", "parent-1")

    assert metadata == {
        "task_type": "job_platform_profile",
        "platform": "boss",
        "profile_key": "job-a",
        "entity_type": "job_platform_profile",
        "entity_id": "boss:job-a",
        "payload": {
            "parent_task_id": "parent-1",
            "platform": "boss",
            "profile_key": "job-a",
        },
    }


def test_profile_lanes_keep_same_profile_serial_and_different_profiles_parallel():
    from app.domains.jobs.crawl_service import _group_profile_lanes_for_parallelism

    groups = {
        ("boss", "job-a"): [SimpleNamespace(id=1)],
        ("51job", "job-a"): [SimpleNamespace(id=2)],
        ("boss", "job-b"): [SimpleNamespace(id=3)],
    }

    lanes = _group_profile_lanes_for_parallelism(groups)

    assert list(lanes) == ["job-a", "job-b"]
    assert [(platform, profile_key) for platform, profile_key, _configs in lanes["job-a"]] == [
        ("boss", "job-a"),
        ("51job", "job-a"),
    ]
    assert [(platform, profile_key) for platform, profile_key, _configs in lanes["job-b"]] == [
        ("boss", "job-b"),
    ]

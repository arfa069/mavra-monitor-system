import json


def test_job_jsonl_logger_writes_common_envelope(tmp_path):
    from app.domains.jobs.runtime import JobCrawlRuntimeContext
    from app.platforms.job_runtime_logging import JobRuntimeJsonlLogger

    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=tmp_path / "profiles" / "job-a",
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )
    log_path = tmp_path / "job-runtime.jsonl"
    logger = JobRuntimeJsonlLogger(platform="boss", context=context, log_path=log_path)

    logger.log("crawl_start", status="running", message="started", count=3)

    payload = json.loads(log_path.read_text(encoding="utf-8").strip())
    assert payload["platform"] == "boss"
    assert payload["profile_key"] == "job-a"
    assert payload["task_id"] == "task-1"
    assert payload["config_id"] == 101
    assert payload["event"] == "crawl_start"
    assert payload["status"] == "running"
    assert payload["count"] == 3

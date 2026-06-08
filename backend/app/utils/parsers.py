"""Text parsing utilities."""
from __future__ import annotations

import re

_RE_SALARY_BONUS = re.compile(r'·\d+薪')
_RE_SALARY_SPACES = re.compile(r'\s+')
_RE_SALARY_RANGE = re.compile(r'(\d+)[kK]?-(\d+)[kK]?')
_RE_SALARY_SINGLE = re.compile(r'^(\d+)[kK]?$')


def parse_salary(salary_str: str | None) -> tuple[int | None, int | None]:
    """Parse salary string like '20-40K·14薪' to (min, max) in K.

    Returns:
        (salary_min, salary_max) in units of K, or (None, None) if unparseable.
    """
    if not salary_str:
        return None, None

    # Remove bonus part like "·14薪"
    salary_str = _RE_SALARY_BONUS.sub('', salary_str)

    if salary_str in ('面议', '薪资面议', '薪资面议 '):
        return None, None

    salary_str = _RE_SALARY_SPACES.sub('', salary_str)

    match = _RE_SALARY_RANGE.match(salary_str)
    if match:
        return int(match.group(1)), int(match.group(2))

    match = _RE_SALARY_SINGLE.match(salary_str.strip())
    if match:
        val = int(match.group(1))
        return val, val

    return None, None

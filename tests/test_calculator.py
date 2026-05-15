import pytest

from app.calculator import estimate_paint


def test_estimate_paint_uses_default_inputs() -> None:
    result = estimate_paint(1000)

    assert result["total_coverage_needed"] == 2000
    assert result["buckets_required"] == 6
    assert result["total_cost"] == 252.0


def test_estimate_paint_rejects_invalid_square_footage() -> None:
    with pytest.raises(ValueError):
        estimate_paint(0)

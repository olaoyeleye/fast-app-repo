from math import ceil


DEFAULT_BUCKET_COVERAGE = 350
DEFAULT_BUCKET_COST = 42.0
DEFAULT_COATS = 2


def estimate_paint(
    square_footage: float,
    coverage_per_bucket: int = DEFAULT_BUCKET_COVERAGE,
    bucket_cost: float = DEFAULT_BUCKET_COST,
    coats: int = DEFAULT_COATS,
) -> dict[str, float | int]:
    if square_footage <= 0:
        raise ValueError("Square footage must be greater than zero.")
    if coverage_per_bucket <= 0:
        raise ValueError("Coverage per bucket must be greater than zero.")
    if bucket_cost < 0:
        raise ValueError("Bucket cost cannot be negative.")
    if coats <= 0:
        raise ValueError("Number of coats must be greater than zero.")

    total_coverage_needed = square_footage * coats
    buckets_required = ceil(total_coverage_needed / coverage_per_bucket)
    total_cost = buckets_required * bucket_cost

    return {
        "square_footage": square_footage,
        "coverage_per_bucket": coverage_per_bucket,
        "bucket_cost": bucket_cost,
        "coats": coats,
        "total_coverage_needed": total_coverage_needed,
        "buckets_required": buckets_required,
        "total_cost": round(total_cost, 2),
    }

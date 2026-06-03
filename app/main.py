from pathlib import Path

from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.calculator import estimate_paint


BASE_DIR = Path(__file__).resolve().parent

app = FastAPI(title="House Paint Estimator" , root_path="/paint-planning")
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))


@app.get("/", response_class=HTMLResponse)
async def index(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "index.html",
        {
            "result": None,
            "error": None,
            "defaults": {
                "square_footage": "",
                "coverage_per_bucket": 350,
                "bucket_cost": 42.0,
                "coats": 2,
            },
        },
    )


@app.post("/estimate", response_class=HTMLResponse)
async def calculate_estimate(
    request: Request,
    square_footage: float = Form(...),
    coverage_per_bucket: int = Form(350),
    bucket_cost: float = Form(42.0),
    coats: int = Form(2),
) -> HTMLResponse:
    defaults = {
        "square_footage": square_footage,
        "coverage_per_bucket": coverage_per_bucket,
        "bucket_cost": bucket_cost,
        "coats": coats,
    }
    try:
        result = estimate_paint(
            square_footage=square_footage,
            coverage_per_bucket=coverage_per_bucket,
            bucket_cost=bucket_cost,
            coats=coats,
        )
        error = None
    except ValueError as exc:
        result = None
        error = str(exc)

    return templates.TemplateResponse(
        request,
        "index.html",
        {
            "result": result,
            "error": error,
            "defaults": defaults,
        },
    )

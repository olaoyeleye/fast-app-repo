# fast-app-repo

A small FastAPI app that estimates the cost of painting a house based on square
footage and calculates how many paint buckets are required.

## Features

- Accepts house square footage
- Estimates required paint buckets
- Calculates total paint cost
- Lets you adjust bucket coverage, bucket price, and number of coats

## Run locally

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Start the app:

```bash
uvicorn app.main:app --reload
```

4. Open [http://127.0.0.1:8000](http://127.0.0.1:8000)

## Default assumptions

- One bucket covers `350` square feet
- Paint costs `$42` per bucket
- The estimate uses `2` coats by default

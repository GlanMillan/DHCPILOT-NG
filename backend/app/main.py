from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from models.database import SessionLocal, init_db

app = FastAPI()

# 依赖项
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.on_event("startup")
async def startup_event():
    init_db()

@app.get("/")
def read_root():
    return {"message": "DHCP Management API Service"}

@app.get("/health")
def health_check():
    return {"status": "healthy"} 
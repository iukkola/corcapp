import os
import uuid
from datetime import datetime
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, String, Float, Date, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from starlette.status import HTTP_400_BAD_REQUEST

# 📦 Asetukset
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# 🛢 PostgreSQL-yhteys
DATABASE_URL = "postgresql://username:password@localhost/dbname"  # ⚠️ Vaihda omiin arvoihisi
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

# 📄 Malli
class Upload(Base):
    __tablename__ = "uploads"
    id = Column(String, primary_key=True, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    plant_type = Column(String)
    planting_date = Column(Date)
    image_path = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# 🚀 API
app = FastAPI()

# 🌐 CORS tarvittaessa mobiilisovellukselle
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # vaihda tarvittaessa
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 📨 Latausrajapinta
@app.post("/upload")
async def upload_data(
    latitude: float = Form(...),
    longitude: float = Form(...),
    plant_type: str = Form(...),
    planting_date: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        planting_date_parsed = datetime.strptime(planting_date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=HTTP_400_BAD_REQUEST, detail="Invalid planting date format. Use YYYY-MM-DD.")

    # Luo uniikki ID ja tiedostopolku
    uid = str(uuid.uuid4())
    filename = f"{uid}_{image.filename}"
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    # Tallenna kuva levylle
    with open(file_path, "wb") as f:
        content = await image.read()
        f.write(content)

    # Tallenna metadata tietokantaan
    db = SessionLocal()
    new_entry = Upload(
        id=uid,
        latitude=latitude,
        longitude=longitude,
        plant_type=plant_type,
        planting_date=planting_date_parsed,
        image_path=file_path,
    )
    db.add(new_entry)
    db.commit()
    db.close()

    return {"status": "success", "id": uid}

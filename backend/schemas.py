from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    language: str = "en"

class UserOut(BaseModel):
    id: int
    email: EmailStr
    language: str

    class Config:
        from_attributes = True

class FieldCreate(BaseModel):
    name: str
    coordinates: List[List[float]]  # [[lat, lon], [lat, lon], ...]
    area_hectares: Optional[float] = None

class FieldOut(BaseModel):
    id: int
    name: str
    coordinates: List[List[float]]
    area_hectares: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True

class PlantingReportCreate(BaseModel):
    field_id: int
    crop_type: str
    planting_date: datetime
    image_url: Optional[str] = None
    notes: Optional[str] = None

class PlantingReportOut(BaseModel):
    id: int
    field_id: int
    crop_type: str
    planting_date: datetime
    image_url: Optional[str]
    notes: Optional[str]
    carbon_credits_earned: float
    created_at: datetime

    class Config:
        from_attributes = True

class NDVIDataOut(BaseModel):
    id: int
    field_id: int
    date: datetime
    ndvi_value: float
    biomass_estimate: Optional[float]
    data_source: str

    class Config:
        from_attributes = True

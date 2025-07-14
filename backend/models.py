from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    language = Column(String, default="en")
    
    fields = relationship("Field", back_populates="owner")

class Field(Base):
    __tablename__ = "fields"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    coordinates = Column(JSON)  # GPS polygon coordinates
    area_hectares = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    owner = relationship("User", back_populates="fields")
    planting_reports = relationship("PlantingReport", back_populates="field")
    ndvi_data = relationship("NDVIData", back_populates="field")

class PlantingReport(Base):
    __tablename__ = "planting_reports"
    
    id = Column(Integer, primary_key=True, index=True)
    field_id = Column(Integer, ForeignKey("fields.id"))
    crop_type = Column(String)
    planting_date = Column(DateTime)
    image_url = Column(String)
    notes = Column(Text)
    carbon_credits_earned = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    field = relationship("Field", back_populates="planting_reports")

class NDVIData(Base):
    __tablename__ = "ndvi_data"
    
    id = Column(Integer, primary_key=True, index=True)
    field_id = Column(Integer, ForeignKey("fields.id"))
    date = Column(DateTime)
    ndvi_value = Column(Float)
    biomass_estimate = Column(Float)
    data_source = Column(String, default="sentinel-2")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    field = relationship("Field", back_populates="ndvi_data")

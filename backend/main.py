from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import models, schemas, auth
from database import SessionLocal, engine, Base
import jwt_token as token_helper
from jwt_token import verify_token
from earth_engine_service import EarthEngineService
from image_analysis_service import ImageAnalysisService
from datetime import datetime, timedelta
from fastapi import Query
import base64

# Alustetaan tietokantataulut
Base.metadata.create_all(bind=engine)

app = FastAPI(title="CORC API", description="Carbon Credit API for farmers")

# CORS middleware for web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
ee_service = EarthEngineService()
image_service = ImageAnalysisService()

# Riippuvuus: tietokantayhteys
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = verify_token(token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    email = payload.get("sub")
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Auth endpoints
@app.post("/register", response_model=schemas.UserOut)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pw = auth.hash_password(user.password)
    new_user = models.User(
        email=user.email,
        hashed_password=hashed_pw,
        language=user.language
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    access_token = token_helper.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/me", response_model=schemas.UserOut)
def read_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# Field management endpoints
@app.post("/fields", response_model=schemas.FieldOut)
def create_field(field: schemas.FieldCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    new_field = models.Field(
        name=field.name,
        owner_id=current_user.id,
        coordinates=field.coordinates,
        area_hectares=field.area_hectares
    )
    db.add(new_field)
    db.commit()
    db.refresh(new_field)
    return new_field

@app.get("/fields", response_model=List[schemas.FieldOut])
def get_user_fields(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(models.Field).filter(models.Field.owner_id == current_user.id).all()

@app.get("/fields/{field_id}/ndvi", response_model=List[schemas.NDVIDataOut])
def get_field_ndvi(field_id: int, days_back: int = 90, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Verify field ownership
    field = db.query(models.Field).filter(models.Field.id == field_id, models.Field.owner_id == current_user.id).first()
    if not field:
        raise HTTPException(status_code=404, detail="Field not found")
    
    # Check if we have recent NDVI data
    recent_data = db.query(models.NDVIData).filter(
        models.NDVIData.field_id == field_id,
        models.NDVIData.date >= datetime.now() - timedelta(days=7)
    ).all()
    
    if not recent_data:
        # Calculate new NDVI data
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days_back)
        
        ndvi_results = ee_service.calculate_ndvi_for_field(
            field.coordinates,
            start_date.strftime('%Y-%m-%d'),
            end_date.strftime('%Y-%m-%d')
        )
        
        # Save to database
        for result in ndvi_results:
            ndvi_data = models.NDVIData(
                field_id=field_id,
                date=datetime.strptime(result['date'], '%Y-%m-%d'),
                ndvi_value=result['ndvi_value'],
                biomass_estimate=ee_service.estimate_biomass_from_ndvi(result['ndvi_value'])
            )
            db.add(ndvi_data)
        
        db.commit()
    
    # Return all NDVI data for the field
    return db.query(models.NDVIData).filter(models.NDVIData.field_id == field_id).order_by(models.NDVIData.date).all()

@app.post("/fields/{field_id}/planting-report", response_model=schemas.PlantingReportOut)
def create_planting_report(field_id: int, report: schemas.PlantingReportCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Verify field ownership
    field = db.query(models.Field).filter(models.Field.id == field_id, models.Field.owner_id == current_user.id).first()
    if not field:
        raise HTTPException(status_code=404, detail="Field not found")
    
    new_report = models.PlantingReport(
        field_id=field_id,
        crop_type=report.crop_type,
        planting_date=report.planting_date,
        image_url=report.image_url,
        notes=report.notes
    )
    db.add(new_report)
    db.commit()
    db.refresh(new_report)
    return new_report

@app.get("/fields/{field_id}/ndvi/satellite")
def get_satellite_ndvi_data(
    field_id: int, 
    start_date: str = Query(..., description="Start date (YYYY-MM-DD)"),
    end_date: str = Query(..., description="End date (YYYY-MM-DD)"),
    current_user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Get fresh NDVI data directly from satellite (Google Earth Engine)"""
    # Verify field ownership
    field = db.query(models.Field).filter(
        models.Field.id == field_id, 
        models.Field.owner_id == current_user.id
    ).first()
    if not field:
        raise HTTPException(status_code=404, detail="Field not found")
    
    # Get fresh satellite data
    try:
        ndvi_data = ee_service.calculate_ndvi_for_field(
            field.coordinates, 
            start_date, 
            end_date
        )
        
        # Format response
        satellite_results = []
        for data_point in ndvi_data:
            biomass = ee_service.estimate_biomass_from_ndvi(data_point['ndvi_value'])
            satellite_results.append({
                "date": data_point['date'],
                "ndvi_value": data_point['ndvi_value'],
                "biomass_estimate": biomass,
                "data_source": "live_satellite",
                "field_id": field_id
            })
        
        return {
            "field_id": field_id,
            "field_name": field.name,
            "data_source": "Google Earth Engine (Live)",
            "date_range": f"{start_date} to {end_date}",
            "total_datapoints": len(satellite_results),
            "ndvi_data": satellite_results
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Satellite data error: {str(e)}")

from pydantic import BaseModel
from typing import Optional

class PhotoAnalysisRequest(BaseModel):
    photo_base64: str
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None

@app.post("/fields/{field_id}/photos/analyze")
def analyze_field_photo(
    field_id: int,
    request: PhotoAnalysisRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze a field photo for biomass estimation and validation"""
    # Verify field ownership
    field = db.query(models.Field).filter(
        models.Field.id == field_id, 
        models.Field.owner_id == current_user.id
    ).first()
    if not field:
        raise HTTPException(status_code=404, detail="Field not found")
    
    try:
        # Decode base64 image
        image_data = base64.b64decode(request.photo_base64)
        
        # Use GPS coordinates from JSON if provided, otherwise try EXIF
        if request.gps_latitude is not None and request.gps_longitude is not None:
            # Use GPS coordinates from Flutter app
            provided_gps = [request.gps_latitude, request.gps_longitude]
            print(f"📍 GPS from Flutter app: {request.gps_latitude:.6f}, {request.gps_longitude:.6f}")
            
            # Analyze the image with provided GPS
            analysis_result = image_service.analyze_field_photo_with_gps(
                image_data=image_data,
                expected_coords=field.coordinates,
                photo_gps_coords=provided_gps
            )
        else:
            # Fallback to EXIF metadata method
            analysis_result = image_service.analyze_field_photo(
                image_data=image_data,
                expected_coords=field.coordinates
            )
            
            # Debug: Print metadata info for EXIF method
            if "metadata" in analysis_result:
                print(f"📷 Photo metadata keys: {list(analysis_result['metadata'].keys())}")
                if "gps_coords" in analysis_result["metadata"]:
                    gps_coords = analysis_result["metadata"]["gps_coords"]
                    print(f"📍 Photo GPS coordinates from EXIF: {gps_coords[0]:.6f}, {gps_coords[1]:.6f}")
                else:
                    print("📍 No GPS coordinates found in photo metadata")
            else:
                print("📷 No metadata found in photo")
        
        # Get recent satellite data for comparison
        recent_satellite_data = ee_service.calculate_ndvi_for_field(
            field.coordinates,
            (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'),
            datetime.now().strftime('%Y-%m-%d')
        )
        
        # Compare with satellite if available
        satellite_comparison = None
        if recent_satellite_data:
            latest_ndvi = recent_satellite_data[-1]['ndvi_value']
            satellite_comparison = image_service.compare_with_satellite_ndvi(
                analysis_result['biomass_estimate_kg_per_hectare'],
                latest_ndvi
            )
        
        return {
            "field_id": field_id,
            "field_name": field.name,
            "image_analysis": analysis_result,
            "satellite_comparison": satellite_comparison,
            "analysis_timestamp": datetime.now().isoformat(),
            "recommendations": generate_recommendations(analysis_result, satellite_comparison)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Photo analysis error: {str(e)}")

def generate_recommendations(image_analysis: dict, satellite_comparison: dict = None) -> list:
    """Generate recommendations based on analysis results"""
    recommendations = []
    
    validation_score = image_analysis.get('validation', {}).get('overall_score', 0)
    green_pct = image_analysis.get('vegetation_analysis', {}).get('green_percentage', 0)
    
    # Validation recommendations
    if validation_score < 70:
        recommendations.append("⚠️ Low validation score - please ensure photo is recent and taken at field location")
    
    if not image_analysis.get('validation', {}).get('freshness_valid', False):
        recommendations.append("📅 Photo appears old - please take a fresh photo within 24 hours")
    
    if not image_analysis.get('validation', {}).get('gps_valid', False):
        recommendations.append("📍 Photo location doesn't match field - please take photo at field boundary")
    
    # Vegetation recommendations
    if green_pct < 10:
        recommendations.append("🌱 Very low vegetation detected - consider planting or irrigation")
    elif green_pct > 80:
        recommendations.append("🌿 Excellent vegetation coverage detected!")
    
    # Satellite comparison recommendations
    if satellite_comparison and not satellite_comparison.get('is_consistent', True):
        recommendations.append("🛰️ Image data differs significantly from satellite data - please verify field conditions")
    
    if not recommendations:
        recommendations.append("✅ All checks passed - good quality field documentation!")
    
    return recommendations

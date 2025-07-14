import cv2
import numpy as np
from PIL import Image, ExifTags
import io
import base64
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import math
import json

class ImageAnalysisService:
    """Service for analyzing field photos and extracting biomass indicators"""
    
    def __init__(self):
        self.min_green_threshold = 0.15  # Minimum percentage of green to be considered valid
        self.max_photo_age_hours = 24    # Photos must be less than 24h old
        self.gps_tolerance_meters = 100   # GPS must be within 100m of field boundary
    
    def analyze_field_photo_with_gps(self, image_data: bytes, expected_coords: List[List[float]], photo_gps_coords: List[float]) -> Dict:
        """
        Analyze a field photo with provided GPS coordinates
        
        Args:
            image_data: Raw image bytes
            expected_coords: Expected field boundary coordinates
            photo_gps_coords: GPS coordinates from the app [latitude, longitude]
            
        Returns:
            Analysis results with biomass estimate and validation status
        """
        try:
            # Load and analyze image
            image = Image.open(io.BytesIO(image_data))
            
            # Create metadata with provided GPS coordinates
            metadata = {
                "gps_coords": photo_gps_coords,
                "datetime": datetime.now().strftime("%Y:%m:%d %H:%M:%S")
            }
            
            # Validate photo freshness (always valid for GPS-provided photos)
            freshness_valid = True
            
            # Validate GPS location using provided coordinates
            gps_valid, gps_distance = self._validate_gps_location_direct(photo_gps_coords, expected_coords)
            
            # Analyze vegetation content
            vegetation_analysis = self._analyze_vegetation(image)
            
            # Calculate biomass estimate from visual data
            biomass_estimate = self._estimate_biomass_from_image(vegetation_analysis)
            
            # Overall validation score
            validation_score = self._calculate_validation_score(
                freshness_valid, gps_valid, vegetation_analysis, gps_distance
            )
            
            return {
                "biomass_estimate_kg_per_hectare": float(biomass_estimate),
                "vegetation_analysis": vegetation_analysis,
                "validation": {
                    "overall_score": float(validation_score),
                    "freshness_valid": bool(freshness_valid),
                    "gps_valid": bool(gps_valid),
                    "gps_distance_meters": float(gps_distance),
                    "photo_timestamp": metadata.get("datetime"),
                    "photo_gps": photo_gps_coords
                },
                "metadata": metadata,
                "analysis_timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "error": f"Image analysis failed: {str(e)}",
                "biomass_estimate_kg_per_hectare": 0.0,
                "validation": {"overall_score": 0.0, "error": True}
            }

    def analyze_field_photo(self, image_data: bytes, expected_coords: List[List[float]], 
                           photo_metadata: Dict = None) -> Dict:
        """
        Analyze a field photo for biomass indicators and validation
        
        Args:
            image_data: Raw image bytes
            expected_coords: Field boundary coordinates [[lat, lon], ...]
            photo_metadata: Optional metadata from photo
            
        Returns:
            Analysis results with biomass estimate and validation status
        """
        try:
            # Load and analyze image
            image = Image.open(io.BytesIO(image_data))
            
            # Extract metadata
            metadata = self._extract_photo_metadata(image)
            
            # Validate photo freshness
            freshness_valid = self._validate_photo_freshness(metadata)
            
            # Validate GPS location
            gps_valid, gps_distance = self._validate_gps_location(metadata, expected_coords)
            
            # Analyze vegetation content
            vegetation_analysis = self._analyze_vegetation(image)
            
            # Calculate biomass estimate from visual data
            biomass_estimate = self._estimate_biomass_from_image(vegetation_analysis)
            
            # Overall validation score
            validation_score = self._calculate_validation_score(
                freshness_valid, gps_valid, vegetation_analysis, gps_distance
            )
            
            return {
                "biomass_estimate_kg_per_hectare": float(biomass_estimate),
                "vegetation_analysis": vegetation_analysis,
                "validation": {
                    "overall_score": float(validation_score),
                    "freshness_valid": bool(freshness_valid),
                    "gps_valid": bool(gps_valid),
                    "gps_distance_meters": float(gps_distance),
                    "photo_timestamp": metadata.get("datetime"),
                    "photo_gps": metadata.get("gps_coords")
                },
                "metadata": metadata,
                "analysis_timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "error": f"Image analysis failed: {str(e)}",
                "biomass_estimate_kg_per_hectare": 0.0,
                "validation": {"overall_score": 0.0, "error": True}
            }
    
    def _extract_photo_metadata(self, image: Image.Image) -> Dict:
        """Extract metadata from photo including GPS and timestamp"""
        metadata = {}
        
        try:
            exif = image._getexif()
            if exif:
                for tag_id, value in exif.items():
                    tag = ExifTags.TAGS.get(tag_id, tag_id)
                    
                    # Extract datetime
                    if tag == "DateTime":
                        metadata["datetime"] = value
                    
                    # Extract GPS data
                    elif tag == "GPSInfo":
                        gps_data = {}
                        for gps_tag_id, gps_value in value.items():
                            gps_tag = ExifTags.GPSTAGS.get(gps_tag_id, gps_tag_id)
                            gps_data[gps_tag] = gps_value
                        
                        # Convert GPS to decimal degrees
                        if "GPSLatitude" in gps_data and "GPSLongitude" in gps_data:
                            lat = self._convert_gps_to_decimal(
                                gps_data["GPSLatitude"], gps_data.get("GPSLatitudeRef", "N")
                            )
                            lon = self._convert_gps_to_decimal(
                                gps_data["GPSLongitude"], gps_data.get("GPSLongitudeRef", "E")
                            )
                            metadata["gps_coords"] = [lat, lon]
                            
        except Exception as e:
            print(f"Metadata extraction error: {e}")
            
        return metadata
    
    def _convert_gps_to_decimal(self, gps_coord, ref) -> float:
        """Convert GPS coordinates from EXIF format to decimal degrees"""
        degrees = float(gps_coord[0])
        minutes = float(gps_coord[1])
        seconds = float(gps_coord[2])
        
        decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)
        
        if ref in ["S", "W"]:
            decimal = -decimal
            
        return decimal
    
    def _validate_photo_freshness(self, metadata: Dict) -> bool:
        """Check if photo was taken recently"""
        if "datetime" not in metadata:
            return False
            
        try:
            photo_time = datetime.strptime(metadata["datetime"], "%Y:%m:%d %H:%M:%S")
            time_diff = datetime.now() - photo_time
            return bool(time_diff.total_seconds() / 3600 <= self.max_photo_age_hours)
        except:
            return False
    
    def _validate_gps_location_direct(self, photo_coords: List[float], expected_coords: List[List[float]]) -> Tuple[bool, float]:
        """Validate GPS location using provided coordinates directly"""
        if not photo_coords or not expected_coords:
            return False, -1.0
        
        # Calculate minimum distance to field boundary
        min_distance = 999999.0
        for field_coord in expected_coords:
            distance = self._calculate_distance(photo_coords, field_coord)
            min_distance = min(min_distance, distance)
        
        is_valid = bool(min_distance <= self.gps_tolerance_meters)
        return is_valid, float(min_distance)

    def _validate_gps_location(self, metadata: Dict, expected_coords: List[List[float]]) -> Tuple[bool, float]:
        """Validate that photo was taken near the field"""
        if "gps_coords" not in metadata or not expected_coords:
            return False, -1.0  # Use -1 instead of inf to indicate no GPS data
        
        photo_coords = metadata["gps_coords"]
        
        # Calculate minimum distance to field boundary
        min_distance = 999999.0  # Large number instead of inf
        for field_coord in expected_coords:
            distance = self._calculate_distance(photo_coords, field_coord)
            min_distance = min(min_distance, distance)
        
        is_valid = bool(min_distance <= self.gps_tolerance_meters)
        return is_valid, float(min_distance)
    
    def _calculate_distance(self, coord1: List[float], coord2: List[float]) -> float:
        """Calculate distance between two GPS coordinates in meters"""
        lat1, lon1 = math.radians(coord1[0]), math.radians(coord1[1])
        lat2, lon2 = math.radians(coord2[0]), math.radians(coord2[1])
        
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        r = 6371000  # Earth radius in meters
        
        return c * r
    
    def _analyze_vegetation(self, image: Image.Image) -> Dict:
        """Analyze vegetation content in the image"""
        # Convert to numpy array
        img_array = np.array(image)
        
        # Convert to HSV for better vegetation detection
        img_hsv = cv2.cvtColor(img_array, cv2.COLOR_RGB2HSV)
        
        # Define green color range (vegetation)
        lower_green = np.array([35, 40, 40])
        upper_green = np.array([85, 255, 255])
        
        # Create mask for green areas
        green_mask = cv2.inRange(img_hsv, lower_green, upper_green)
        
        # Calculate vegetation metrics
        total_pixels = img_array.shape[0] * img_array.shape[1]
        green_pixels = np.sum(green_mask > 0)
        green_percentage = (green_pixels / total_pixels) * 100
        
        # Analyze vegetation density and health
        vegetation_density = self._calculate_vegetation_density(green_mask)
        vegetation_health = self._estimate_vegetation_health(img_hsv, green_mask)
        
        return {
            "green_percentage": round(green_percentage, 2),
            "vegetation_density": round(vegetation_density, 2),
            "vegetation_health_score": round(vegetation_health, 2),
            "total_pixels": float(total_pixels),
            "green_pixels": float(green_pixels)
        }
    
    def _calculate_vegetation_density(self, green_mask: np.ndarray) -> float:
        """Calculate how dense the vegetation appears"""
        # Use morphological operations to analyze vegetation structure
        kernel = np.ones((5,5), np.uint8)
        closing = cv2.morphologyEx(green_mask, cv2.MORPH_CLOSE, kernel)
        
        # Calculate ratio of filled vs sparse areas
        density_ratio = np.sum(closing > 0) / max(np.sum(green_mask > 0), 1)
        return min(density_ratio * 100, 100)
    
    def _estimate_vegetation_health(self, img_hsv: np.ndarray, green_mask: np.ndarray) -> float:
        """Estimate vegetation health based on color characteristics"""
        if np.sum(green_mask) == 0:
            return 0
        
        # Extract green areas
        green_areas = img_hsv[green_mask > 0]
        
        if len(green_areas) == 0:
            return 0
        
        # Analyze hue and saturation of green areas
        avg_hue = np.mean(green_areas[:, 0])
        avg_saturation = np.mean(green_areas[:, 1])
        avg_value = np.mean(green_areas[:, 2])
        
        # Healthy vegetation typically has:
        # - Hue around 60 (green)
        # - High saturation (vivid color)
        # - Moderate to high value (brightness)
        
        hue_score = max(0, 100 - abs(avg_hue - 60) * 2)
        saturation_score = (avg_saturation / 255) * 100
        brightness_score = (avg_value / 255) * 100
        
        # Weighted average
        health_score = (hue_score * 0.4 + saturation_score * 0.4 + brightness_score * 0.2)
        return min(health_score, 100)
    
    def _estimate_biomass_from_image(self, vegetation_analysis: Dict) -> float:
        """Estimate biomass based on vegetation analysis"""
        green_pct = vegetation_analysis["green_percentage"]
        density = vegetation_analysis["vegetation_density"]
        health = vegetation_analysis["vegetation_health_score"]
        
        # Simplified biomass calculation (kg per hectare)
        # This would be calibrated with real field data
        base_biomass = 100  # Base biomass per hectare
        
        # Factors based on visual analysis
        coverage_factor = green_pct / 100
        density_factor = density / 100
        health_factor = health / 100
        
        biomass_estimate = base_biomass * coverage_factor * density_factor * health_factor * 50
        
        return round(biomass_estimate, 2)
    
    def _calculate_validation_score(self, freshness_valid: bool, gps_valid: bool, 
                                  vegetation_analysis: Dict, gps_distance: float) -> float:
        """Calculate overall validation score (0-100)"""
        score = 0
        
        # Freshness (25 points)
        if freshness_valid:
            score += 25
        
        # GPS validation (25 points)
        if gps_valid:
            score += 25
        elif gps_distance > 0 and gps_distance < 999999:  # Valid distance measurement
            # Partial points based on distance
            score += max(0, 25 - (gps_distance / 10))
        
        # Vegetation realism (25 points)
        green_pct = vegetation_analysis["green_percentage"]
        if 5 <= green_pct <= 95:  # Realistic range
            score += 25
        else:
            score += max(0, 25 - abs(green_pct - 50) / 2)
        
        # Image quality (25 points)
        if vegetation_analysis["total_pixels"] > 100000:  # Reasonable resolution
            score += 25
        else:
            score += (vegetation_analysis["total_pixels"] / 100000) * 25
        
        return round(min(score, 100), 1)

    def compare_with_satellite_ndvi(self, image_biomass: float, satellite_ndvi: float) -> Dict:
        """Compare image-based biomass with satellite NDVI data"""
        # Convert NDVI to expected biomass range (simplified)
        expected_biomass = satellite_ndvi * 10000  # Rough conversion
        
        difference = abs(image_biomass - expected_biomass)
        relative_difference = (difference / max(expected_biomass, 1)) * 100
        
        # Determine if values are consistent
        is_consistent = bool(relative_difference < 50)  # Within 50% is considered consistent
        
        confidence_score = max(0, 100 - relative_difference)
        
        return {
            "image_biomass": float(image_biomass),
            "satellite_expected_biomass": float(expected_biomass),
            "difference": round(float(difference), 2),
            "relative_difference_percent": round(float(relative_difference), 2),
            "is_consistent": is_consistent,
            "confidence_score": round(float(confidence_score), 1),
            "satellite_ndvi": float(satellite_ndvi)
        }
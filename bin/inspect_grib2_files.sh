#!/bin/bash
# GRIB2 File Inspector
# Analyzes GRIB2 files in the current directory and provides useful information
# Displays basic info on screen and logs detailed info to LOG/grib2/ folder

# Function to format file sizes
format_size() {
    local size=$1
    if [ $size -gt 1048576 ]; then
        echo "$(( size / 1048576 )) MB"
    elif [ $size -gt 1024 ]; then
        echo "$(( size / 1024 )) KB" 
    else
        echo "${size} bytes"
    fi
}

# Setup logging directories
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="LOG/grib2"
DETAIL_LOG="${LOG_DIR}/grib2_detailed_${TIMESTAMP}.log"
SUMMARY_LOG="${LOG_DIR}/grib2_summary_${TIMESTAMP}.log"
INVENTORY_LOG="${LOG_DIR}/grib2_inventory_${TIMESTAMP}.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log to both screen and detailed log
log_both() {
    echo "$1"
    echo "$1" >> "$DETAIL_LOG"
}

# Function to log only to detailed log
log_detail() {
    echo "$1" >> "$DETAIL_LOG"
}

# Function to log to summary log
log_summary() {
    echo "$1" >> "$SUMMARY_LOG"
}

echo "========================================"
echo "GRIB2 File Inspection Report"
echo "========================================"
echo "Directory: $(pwd)"
echo "Timestamp: $(date)"
echo "Detailed logs: $LOG_DIR/"
echo ""

# Initialize detailed log
log_detail "========================================"
log_detail "DETAILED GRIB2 File Inspection Report"
log_detail "========================================"
log_detail "Directory: $(pwd)"
log_detail "Timestamp: $(date)"
log_detail "Log files:"
log_detail "  Detailed: $DETAIL_LOG"
log_detail "  Summary: $SUMMARY_LOG"
log_detail "  Inventory: $INVENTORY_LOG"
log_detail ""

# Check if wgrib2 is available
if ! command -v wgrib2 &> /dev/null; then
    echo "ERROR: wgrib2 command not found. Cannot inspect GRIB2 files."
    exit 1
fi

# Find all GRIB2 files
GRIB_FILES=$(find . -maxdepth 2 -name "*.grib2" -o -name "gfs.t*" -o -name "*.grb2" 2>/dev/null | sort)

if [ -z "$GRIB_FILES" ]; then
    log_both "No GRIB2 files found in current directory or GRIB/ subdirectory."
    log_both ""
    log_both "Looking for any files that might be GRIB2:"
    find . -maxdepth 2 -type f -exec file {} \; 2>/dev/null | grep -i grib || log_both "No GRIB files detected."
    exit 0
fi

echo "GRIB2 Files Found:"
echo "------------------"
log_detail "GRIB2 Files Found:"
log_detail "------------------"

# Initialize summary log
log_summary "GRIB2 Inspection Summary - $(date)"
log_summary "=================================="

total_files=0
total_size=0

for grib_file in $GRIB_FILES; do
    if [ -f "$grib_file" ]; then
        total_files=$((total_files + 1))
        file_size=$(stat -c%s "$grib_file" 2>/dev/null || echo "0")
        total_size=$((total_size + file_size))
        
        # Basic info on screen
        echo "File: $grib_file ($(format_size $file_size))"
        
        # Detailed info to logs
        log_detail "File: $grib_file"
        log_detail "  Size: $(format_size $file_size)"
        log_detail "  Modified: $(stat -c%y "$grib_file" 2>/dev/null || echo "unknown")"
        
        # Summary for this file
        log_summary "File: $grib_file"
        log_summary "  Size: $(format_size $file_size)"
        
        # Get basic GRIB2 info
        basic_info=$(wgrib2 -s "$grib_file" 2>/dev/null | head -1)
        if [ -n "$basic_info" ]; then
            date_time=$(echo "$basic_info" | awk -F: '{print $3}')
            parameter=$(echo "$basic_info" | awk -F: '{print $4}')
            level=$(echo "$basic_info" | awk -F: '{print $5}')
            echo "  Date/Time: $date_time"
            log_detail "  Basic Info:"
            log_detail "    Date/Time: $date_time"
            log_detail "    First Parameter: $parameter"
            log_detail "    First Level: $level"
        fi
        
        # Count total records
        record_count=$(wgrib2 -s "$grib_file" 2>/dev/null | wc -l)
        echo "  Records: $record_count"
        log_detail "    Total records: $record_count"
        log_summary "  Records: $record_count"
        
        # Generate complete inventory for detailed log
        log_detail "  Complete Inventory:"
        echo "========================================" >> "$INVENTORY_LOG"
        echo "File: $grib_file" >> "$INVENTORY_LOG"
        echo "Date: $(date)" >> "$INVENTORY_LOG"
        echo "========================================" >> "$INVENTORY_LOG"
        wgrib2 -s "$grib_file" 2>/dev/null >> "$INVENTORY_LOG"
        echo "" >> "$INVENTORY_LOG"
        
        # Check for key surface fields
        log_detail "  Key Surface Fields:"
        pmsl_field=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E "(PRMSL|MSLET):mean sea level" | head -1 | awk -F: '{print $4}')
        if [ -n "$pmsl_field" ]; then
            echo "  Sea Level Pressure: ✓"
            log_detail "    Sea Level Pressure: $pmsl_field"
            log_summary "  Sea Level Pressure: ✓"
        else
            echo "  Sea Level Pressure: ✗"
            log_detail "    Sea Level Pressure: NOT FOUND"
            log_summary "  Sea Level Pressure: ✗"
        fi
        
        psfc_field=$(wgrib2 -s "$grib_file" 2>/dev/null | grep "PRES:surface" | head -1 | awk -F: '{print $4}')
        if [ -n "$psfc_field" ]; then
            log_detail "    Surface Pressure: $psfc_field"
        else
            log_detail "    Surface Pressure: NOT FOUND"
        fi
        
        temp_field=$(wgrib2 -s "$grib_file" 2>/dev/null | grep "TMP:surface" | head -1 | awk -F: '{print $4}')
        if [ -n "$temp_field" ]; then
            log_detail "    Surface Temperature: $temp_field"
        else
            log_detail "    Surface Temperature: NOT FOUND"
        fi
        
        # Detailed field analysis
        log_detail "  DETAILED FIELD ANALYSIS:"
        log_detail "  ========================"
        
        # All unique parameters
        log_detail "  All Parameters Found:"
        all_params=$(wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $4}' | sort | uniq)
        param_count=$(echo "$all_params" | wc -l)
        echo "  Total Parameters: $param_count"
        log_detail "    Total unique parameters: $param_count"
        log_summary "  Total Parameters: $param_count"
        
        # List all parameters in detail log
        echo "$all_params" | while read param; do
            if [ -n "$param" ]; then
                count=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -c ":$param:")
                log_detail "    $param ($count records)"
            fi
        done
        
        # All unique levels  
        log_detail "  All Levels Found:"
        all_levels=$(wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $5}' | sort | uniq)
        level_count=$(echo "$all_levels" | wc -l)
        echo "  Total Level Types: $level_count"
        log_detail "    Total unique level types: $level_count"
        log_summary "  Total Level Types: $level_count"
        
        # List all levels in detail log
        echo "$all_levels" | while read level; do
            if [ -n "$level" ]; then
                count=$(wgrib2 -s "$grib_file" 2>/dev/null | awk -F: -v lvl="$level" '$5 == lvl' | wc -l)
                log_detail "    $level ($count records)"
            fi
        done
        
        # Check for atmospheric levels (detailed logging)
        log_detail "  Pressure Levels:"
        pressure_levels=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":[0-9]+ mb:" | awk -F: '{print $5}' | awk '{print $1}' | sort -n | uniq | tr '\n' ' ')
        if [ -n "$pressure_levels" ]; then
            pressure_level_count=$(echo $pressure_levels | wc -w)
            echo "  Pressure Levels: $pressure_level_count levels"
            log_detail "    Available ($pressure_level_count levels): $pressure_levels"
            log_summary "  Pressure Levels: $pressure_level_count levels"
        else
            echo "  Pressure Levels: None"
            log_detail "    No standard pressure levels found"
            log_summary "  Pressure Levels: None"
        fi
        
        # Detailed atmospheric field analysis
        log_detail "  ATMOSPHERIC FIELDS ANALYSIS:"
        log_detail "  ============================="
        
        # Temperature fields
        log_detail "  Temperature Fields:"
        temp_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":TMP:" | wc -l)
        echo "  Temperature Fields: $temp_fields"
        log_summary "  Temperature Fields: $temp_fields"
        if [ $temp_fields -gt 0 ]; then
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":TMP:" | awk -F: '{print "    " $4 " at " $5}' >> "$DETAIL_LOG"
        fi
        
        # Wind fields  
        log_detail "  Wind Fields:"
        ugrd_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":UGRD:" | wc -l)
        vgrd_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":VGRD:" | wc -l)
        wind_fields=$((ugrd_fields + vgrd_fields))
        echo "  Wind Fields: $wind_fields (U: $ugrd_fields, V: $vgrd_fields)"
        log_summary "  Wind Fields: $wind_fields (U: $ugrd_fields, V: $vgrd_fields)"
        if [ $ugrd_fields -gt 0 ]; then
            log_detail "    U-Wind Components:"
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":UGRD:" | awk -F: '{print "      " $5}' >> "$DETAIL_LOG"
        fi
        if [ $vgrd_fields -gt 0 ]; then
            log_detail "    V-Wind Components:"
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":VGRD:" | awk -F: '{print "      " $5}' >> "$DETAIL_LOG"
        fi
        
        # Humidity fields
        log_detail "  Humidity Fields:"
        rh_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":RH:" | wc -l)
        spfh_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":SPFH:" | wc -l)
        humidity_fields=$((rh_fields + spfh_fields))
        echo "  Humidity Fields: $humidity_fields (RH: $rh_fields, SPFH: $spfh_fields)"
        log_summary "  Humidity Fields: $humidity_fields"
        if [ $rh_fields -gt 0 ]; then
            log_detail "    Relative Humidity levels:"
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":RH:" | awk -F: '{print "      " $5}' >> "$DETAIL_LOG"
        fi
        if [ $spfh_fields -gt 0 ]; then
            log_detail "    Specific Humidity levels:"
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":SPFH:" | awk -F: '{print "      " $5}' >> "$DETAIL_LOG"
        fi
        
        # Geopotential height
        log_detail "  Geopotential Height Fields:"
        hgt_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":HGT:" | wc -l)
        echo "  Geopotential Height Fields: $hgt_fields"
        log_summary "  Geopotential Height Fields: $hgt_fields"
        if [ $hgt_fields -gt 0 ]; then
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":HGT:" | awk -F: '{print "    " $5}' >> "$DETAIL_LOG"
        fi
        
        # Vertical velocity
        log_detail "  Vertical Motion Fields:"
        vvel_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":VVEL:" | wc -l)
        echo "  Vertical Velocity Fields: $vvel_fields"
        log_summary "  Vertical Velocity Fields: $vvel_fields"
        if [ $vvel_fields -gt 0 ]; then
            wgrib2 -s "$grib_file" 2>/dev/null | grep ":VVEL:" | awk -F: '{print "    " $5}' >> "$DETAIL_LOG"
        fi
        
        # Precipitation fields
        log_detail "  Precipitation Fields:"
        precip_count=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":(APCP|ACPCP|PRATE):" | wc -l)
        echo "  Precipitation Fields: $precip_count"
        log_summary "  Precipitation Fields: $precip_count"
        if [ $precip_count -gt 0 ]; then
            wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":(APCP|ACPCP|PRATE):" | awk -F: '{print "    " $4 " at " $5}' >> "$DETAIL_LOG"
        fi
        
        # Cloud fields
        log_detail "  Cloud Fields:"
        cloud_count=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":(TCDC|LCDC|MCDC|HCDC|CLWMR|CICE):" | wc -l)
        echo "  Cloud Fields: $cloud_count"
        log_summary "  Cloud Fields: $cloud_count"
        if [ $cloud_count -gt 0 ]; then
            wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":(TCDC|LCDC|MCDC|HCDC|CLWMR|CICE):" | awk -F: '{print "    " $4 " at " $5}' >> "$DETAIL_LOG"
        fi
        
        # Check for soil fields
        log_detail "  SOIL FIELDS ANALYSIS:"
        log_detail "  ====================="
        soil_count=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -c "below ground" || echo "0")
        if [ $soil_count -gt 0 ]; then
            echo "  Soil Fields: $soil_count records"
            log_detail "  Soil Fields: $soil_count records found"
            log_summary "  Soil Fields: $soil_count records"
            # List all soil fields in detail log
            log_detail "    Soil field details:"
            wgrib2 -s "$grib_file" 2>/dev/null | grep "below ground" | awk -F: '{print "      " $4 " " $5}' >> "$DETAIL_LOG"
            
            # Soil temperature
            soil_temp=$(wgrib2 -s "$grib_file" 2>/dev/null | grep "TMP.*below ground" | wc -l)
            log_detail "    Soil Temperature levels: $soil_temp"
            
            # Soil moisture
            soil_moist=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E "(SOILW|SOILM).*below ground" | wc -l)
            log_detail "    Soil Moisture levels: $soil_moist"
        else
            echo "  Soil Fields: None"
            log_detail "  Soil Fields: NOT FOUND"
            log_summary "  Soil Fields: None"
        fi
        
        # Time analysis
        log_detail "  TIME ANALYSIS:"
        log_detail "  =============="
        all_times=$(wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $3}' | sort | uniq)
        time_count=$(echo "$all_times" | wc -l)
        echo "  Time Steps: $time_count"
        log_summary "  Time Steps: $time_count"
        log_detail "    Available times:"
        echo "$all_times" | while read time_step; do
            if [ -n "$time_step" ]; then
                count=$(wgrib2 -s "$grib_file" 2>/dev/null | awk -F: -v ts="$time_step" '$3 == ts' | wc -l)
                log_detail "      $time_step ($count records)"
            fi
        done
        
        # Forecast hours analysis
        forecast_hours=$(wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $3}' | grep -o '[0-9]\+ hour fcst' | awk '{print $1}' | sort -n | uniq | tr '\n' ' ')
        if [ -n "$forecast_hours" ]; then
            log_detail "    Forecast hours: $forecast_hours"
        fi
        
        # Generate comprehensive field summary table
        log_detail "  COMPREHENSIVE FIELD SUMMARY:"
        log_detail "  ============================="
        log_detail "  Parameter | Level | Count | Time Range"
        log_detail "  ----------|-------|-------|------------"
        
        # Create a temporary file for field analysis
        temp_fields="/tmp/grib_fields_$$"
        wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{printf "%-10s | %-15s | %s\n", $4, $5, $3}' | sort | uniq -c | sort -nr > "$temp_fields"
        
        # Add field summary to detail log
        while read line; do
            log_detail "  $line"
        done < "$temp_fields"
        rm -f "$temp_fields"
        
        # Surface vs upper-air analysis
        log_detail "  SURFACE vs UPPER-AIR ANALYSIS:"
        log_detail "  ==============================="
        surface_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":(surface|mean sea level|10 m above ground|2 m above ground):" | wc -l)
        upperair_fields=$(wgrib2 -s "$grib_file" 2>/dev/null | grep -E ":[0-9]+ mb:" | wc -l)
        other_fields=$((record_count - surface_fields - upperair_fields))
        
        echo "  Surface Fields: $surface_fields"
        echo "  Upper-air Fields: $upperair_fields"  
        echo "  Other Fields: $other_fields"
        log_detail "    Surface fields: $surface_fields"
        log_detail "    Upper-air fields: $upperair_fields"
        log_detail "    Other fields: $other_fields"
        log_summary "  Surface/Upper-air/Other: $surface_fields/$upperair_fields/$other_fields"
        
        # Geographic coverage
        log_detail "  GEOGRAPHIC COVERAGE:"
        log_detail "  ==================="
        grid_info=$(wgrib2 -grid "$grib_file" 2>/dev/null | head -1)
        log_detail "    Grid info: $grid_info"
        if [[ $grid_info =~ lon\ ([0-9.-]+)\ to\ ([0-9.-]+).*lat\ ([0-9.-]+)\ to\ ([0-9.-]+) ]]; then
            echo "  Coverage: ${BASH_REMATCH[1]} to ${BASH_REMATCH[2]} lon, ${BASH_REMATCH[3]} to ${BASH_REMATCH[4]} lat"
            log_summary "  Coverage: ${BASH_REMATCH[1]} to ${BASH_REMATCH[2]} lon, ${BASH_REMATCH[3]} to ${BASH_REMATCH[4]} lat"
        fi
        
        # Grid resolution analysis
        grid_details=$(wgrib2 -grid "$grib_file" 2>/dev/null | head -1)
        if [[ $grid_details =~ ([0-9]+)\ x\ ([0-9]+) ]]; then
            grid_points=$((${BASH_REMATCH[1]} * ${BASH_REMATCH[2]}))
            echo "  Grid Points: ${BASH_REMATCH[1]} x ${BASH_REMATCH[2]} = $grid_points total"
            log_detail "    Grid dimensions: ${BASH_REMATCH[1]} x ${BASH_REMATCH[2]} = $grid_points points"
            log_summary "  Grid: ${BASH_REMATCH[1]} x ${BASH_REMATCH[2]} ($grid_points points)"
        fi
        
        # Advanced analysis - data ranges and statistics (if file is not too large)
        if [ $record_count -lt 1000 ]; then
            log_detail "  STATISTICAL ANALYSIS:"
            log_detail "  ====================="
            log_detail "  (Limited analysis - showing first few records with data ranges)"
            
            # Sample data values for key fields
            sample_fields="TMP:surface PRMSL:mean_sea_level UGRD:10_m_above_ground VGRD:10_m_above_ground"
            for field_pattern in $sample_fields; do
                field_name=$(echo $field_pattern | cut -d: -f1)
                level_pattern=$(echo $field_pattern | cut -d: -f2 | tr '_' ' ')
                
                sample_record=$(wgrib2 -s "$grib_file" 2>/dev/null | grep ":$field_name:" | grep "$level_pattern" | head -1)
                if [ -n "$sample_record" ]; then
                    record_num=$(echo "$sample_record" | cut -d: -f1)
                    log_detail "    $field_name at $level_pattern:"
                    
                    # Get basic stats (min, max, mean) if wgrib2 supports it
                    stats=$(wgrib2 -s -stats "$grib_file" 2>/dev/null | grep "^$record_num:" | head -1)
                    if [ -n "$stats" ]; then
                        log_detail "      $stats"
                    else
                        log_detail "      Record $record_num found (detailed stats not available)"
                    fi
                fi
            done
        else
            log_detail "  STATISTICAL ANALYSIS:"
            log_detail "  ====================="
            log_detail "  (Skipped - file too large with $record_count records)"
        fi
        
        # Create a separate detailed inventory file for this specific file
        detailed_inventory="${LOG_DIR}/detailed_inventory_$(basename $grib_file)_${TIMESTAMP}.txt"
        log_detail "  Creating detailed inventory file: $detailed_inventory"
        
        echo "DETAILED GRIB2 INVENTORY FOR: $grib_file" > "$detailed_inventory"
        echo "Generated: $(date)" >> "$detailed_inventory"
        echo "========================================" >> "$detailed_inventory"
        echo "" >> "$detailed_inventory"
        
        # Full inventory with enhanced formatting
        echo "COMPLETE RECORD LISTING:" >> "$detailed_inventory"
        echo "========================" >> "$detailed_inventory"
        wgrib2 -s "$grib_file" 2>/dev/null | nl -w3 -s": " >> "$detailed_inventory"
        
        echo "" >> "$detailed_inventory"
        echo "PARAMETER SUMMARY:" >> "$detailed_inventory"
        echo "==================" >> "$detailed_inventory"
        wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $4}' | sort | uniq -c | sort -nr >> "$detailed_inventory"
        
        echo "" >> "$detailed_inventory"
        echo "LEVEL SUMMARY:" >> "$detailed_inventory"
        echo "==============" >> "$detailed_inventory"
        wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $5}' | sort | uniq -c | sort -nr >> "$detailed_inventory"
        
        echo "" >> "$detailed_inventory"
        echo "TIME SUMMARY:" >> "$detailed_inventory"
        echo "=============" >> "$detailed_inventory"
        wgrib2 -s "$grib_file" 2>/dev/null | awk -F: '{print $3}' | sort | uniq -c | sort >> "$detailed_inventory"
        
        log_summary "  Detailed inventory: $detailed_inventory"
        
        echo ""
        log_detail ""
        log_summary ""
    fi
done

echo "========================================"
echo "Summary:"
echo "  Total files: $total_files"
echo "  Total size: $(format_size $total_size)"
echo "========================================"

# Log final summary
log_summary ""
log_summary "FINAL SUMMARY:"
log_summary "=============="
log_summary "Total files: $total_files"
log_summary "Total size: $(format_size $total_size)"

log_detail ""
log_detail "========================================"
log_detail "FINAL SUMMARY:"
log_detail "  Total files: $total_files"  
log_detail "  Total size: $(format_size $total_size)"
log_detail "========================================"

# Check if files cover expected geographic area (Canary Islands)
echo ""
echo "Canary Islands Coverage Check:"
echo "------------------------------"
log_detail ""
log_detail "Canary Islands Coverage Check:"
log_detail "------------------------------"

if [ $total_files -gt 0 ]; then
    first_file=$(echo $GRIB_FILES | awk '{print $1}')
    # Test if point in Canary Islands (28.358, -15.838) has data
    canary_test=$(wgrib2 -lon -15.838 28.358 "$first_file" 2>/dev/null | head -1)
    if [ -n "$canary_test" ]; then
        echo "✓ GRIB data covers Canary Islands region"
        log_detail "✓ GRIB data covers Canary Islands region"
        log_detail "  Test coordinates: 28.358°N, -15.838°W"
        log_detail "  Sample data: $canary_test"
        log_summary "Canary Islands Coverage: ✓ CONFIRMED"
    else
        echo "✗ WARNING: GRIB data may not cover Canary Islands region"
        echo "  Test coordinates: 28.358°N, -15.838°W"
        log_detail "✗ WARNING: GRIB data may not cover Canary Islands region"
        log_detail "  Test coordinates: 28.358°N, -15.838°W"
        log_summary "Canary Islands Coverage: ✗ WARNING - NO COVERAGE"
    fi
else
    echo "No files to test"
    log_detail "No files to test"
    log_summary "Canary Islands Coverage: No files to test"
fi

echo ""
echo "Inspection complete."
echo "Detailed logs saved to:"
echo "  - $DETAIL_LOG"
echo "  - $SUMMARY_LOG" 
echo "  - $INVENTORY_LOG"

log_detail ""
log_detail "Inspection completed at $(date)"
log_summary ""
log_summary "Inspection completed at $(date)"
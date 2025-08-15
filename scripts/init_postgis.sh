#!/usr/bin/env bash
set -euo pipefail

# PostGIS Initialization Script
# שימוש: bash scripts/init_postgis.sh [DB_HOST] [DB_PORT] [DB_NAME] [DB_USER] [DB_PASSWORD]

DB_HOST="${1:-localhost}"
DB_PORT="${2:-5432}"
DB_NAME="${3:-asterra_db}"
DB_USER="${4:-postgres}"
DB_PASSWORD="${5:-}"

echo ">>> Initializing PostGIS database..."
echo ">>> Host: $DB_HOST"
echo ">>> Port: $DB_PORT"
echo ">>> Database: $DB_NAME"
echo ">>> User: $DB_USER"

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql command not found. Please install PostgreSQL client."
    exit 1
fi

# Set password if provided
if [ -n "$DB_PASSWORD" ]; then
    export PGPASSWORD="$DB_PASSWORD"
fi

# Test connection
echo ">>> Testing database connection..."
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to database. Please check your credentials."
    exit 1
fi

echo "✅ Database connection successful!"

# Enable PostGIS extension
echo ">>> Enabling PostGIS extension..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Verify PostGIS installation
SELECT PostGIS_Version();
EOF

# Create sample spatial tables
echo ">>> Creating sample spatial tables..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
-- Create sample points table
CREATE TABLE IF NOT EXISTS sample_points (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location GEOMETRY(POINT, 4326),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sample polygons table
CREATE TABLE IF NOT EXISTS sample_polygons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    area_name VARCHAR(100),
    boundary GEOMETRY(POLYGON, 4326),
    area_sq_meters DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial indexes
CREATE INDEX IF NOT EXISTS idx_sample_points_location ON sample_points USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_sample_polygons_boundary ON sample_polygons USING GIST (boundary);

-- Insert sample data
INSERT INTO sample_points (name, description, location) VALUES
    ('Tel Aviv Center', 'Central Tel Aviv', ST_GeomFromText('POINT(34.7818 32.0853)', 4326)),
    ('Jerusalem Old City', 'Historic Jerusalem', ST_GeomFromText('POINT(35.2137 31.7683)', 4326)),
    ('Haifa Port', 'Haifa Port Area', ST_GeomFromText('POINT(34.9896 32.7940)', 4326))
ON CONFLICT DO NOTHING;

-- Insert sample polygon (Tel Aviv area)
INSERT INTO sample_polygons (name, area_name, boundary, area_sq_meters) VALUES
    ('Tel Aviv Area', 'Central District', 
     ST_GeomFromText('POLYGON((34.75 32.05, 34.80 32.05, 34.80 32.10, 34.75 32.10, 34.75 32.05))', 4326),
     ST_Area(ST_GeomFromText('POLYGON((34.75 32.05, 34.80 32.05, 34.80 32.10, 34.75 32.10, 34.75 32.05))', 4326))
    )
ON CONFLICT DO NOTHING;
EOF

# Verify tables and data
echo ">>> Verifying tables and data..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
-- List tables
\dt

-- Count records in sample tables
SELECT 'sample_points' as table_name, COUNT(*) as record_count FROM sample_points
UNION ALL
SELECT 'sample_polygons' as table_name, COUNT(*) as record_count FROM sample_polygons;

-- Show sample spatial query
SELECT 
    p.name as point_name,
    poly.name as polygon_name,
    ST_Distance(p.location, poly.boundary) as distance_meters
FROM sample_points p
CROSS JOIN sample_polygons poly
LIMIT 5;
EOF

echo "✅ PostGIS initialization completed successfully!"
echo ">>> Sample spatial data has been created."
echo ">>> You can now use PostGIS spatial functions in your application." 
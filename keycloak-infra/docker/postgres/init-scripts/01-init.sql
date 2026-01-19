-- Initialize Keycloak database
-- This script runs automatically when the PostgreSQL container starts for the first time

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'Keycloak database initialized successfully';
END $$;


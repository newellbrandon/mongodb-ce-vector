#!/bin/bash
set -e

echo "Starting MongoDB initialization..."
sleep 2

# Environment variables are now available directly from docker-compose.yml

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
until mongosh --host localhost --port 27017 --eval "print('MongoDB is ready')" > /dev/null 2>&1; do
    echo "Waiting for MongoDB to start..."
    sleep 2
done

# Initialize replica set first
echo "Initializing replica set..."
mongosh --host localhost --port 27017 --eval "
try {
    rs.initiate({
        _id: 'rs0',
        members: [
            { _id: 0, host: 'mongod.search-community:27017' }
        ]
    });
    print('Replica set initialized successfully');
} catch (error) {
    if (error.code === 23) {
        print('Replica set already initialized');
    } else {
        print('Error initializing replica set: ' + error);
    }
}
"

# Wait for replica set to be ready
echo "Waiting for replica set to be ready..."
sleep 10

# Create admin user
echo "Creating admin user..."
mongosh --host localhost --port 27017 --eval "
const adminDb = db.getSiblingDB('admin');
try {
adminDb.createUser({
   user: '$MONGODB_INITDB_ROOT_USERNAME',
   pwd: '$MONGODB_INITDB_ROOT_PASSWORD',
   roles: [{ role: 'root', db: 'admin' }]
});
print('Admin user created successfully');
} catch (error) {
if (error.code === 11000) {
   print('Admin user already exists');
} else {
   print('Error creating admin user: ' + error);
}
}
"

# Create mongot user
echo "Creating mongot user..."
mongosh --host localhost --port 27017 --eval "
const adminDb = db.getSiblingDB('admin');
try {
adminDb.createUser({
   user: 'mongotUser',
   pwd: '$MONGODB_MONGOTUSER_PASSWORD',
   roles: [{ role: 'searchCoordinator', db: 'admin' }]
});
print('User mongotUser created successfully');
} catch (error) {
if (error.code === 11000) {
   print('User mongotUser already exists');
} else {
   print('Error creating user: ' + error);
}
}
"

# Check for existing data
echo "Checking for existing sample data..."
if mongosh --host localhost --port 27017 -u "$MONGODB_INITDB_ROOT_USERNAME" -p "$MONGODB_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --quiet --eval "db.getSiblingDB('sample_airbnb').getCollectionNames().includes('listingsAndReviews')" | grep -q "true"; then
echo "Sample data already exists. Skipping restore."
else
echo "Sample data not found. Running mongorestore..."
if [ -f "/sampledata.archive" ]; then
   mongorestore --archive=/sampledata.archive
   echo "Sample data restored successfully."
else
   echo "Warning: sampledata.archive not found"
fi
fi

# Enable authentication after users are created
echo "Enabling authentication..."
echo "Authentication will be enabled on next restart with keyfile configuration"

echo "MongoDB initialization completed."
#!/bin/bash
set -e

echo "Starting MongoDB initialization..."
sleep 5

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
until mongosh --host localhost --port 27017 --eval "print('MongoDB is ready')" > /dev/null 2>&1; do
    echo "Waiting for MongoDB to start..."
    sleep 2
done

# Initialize replica set
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
  if (error.message.includes('already initialized')) {
    print('Replica set already initialized');
  } else {
    print('Error initializing replica set: ' + error);
  }
}
"

# Wait for replica set to be ready
echo "Waiting for replica set to be ready..."
sleep 15

# Wait for admin user to be created by MongoDB
echo "Waiting for admin user to be created..."
sleep 10

# Create user for MongoT
echo "Creating mongotUser for MongoT..."
mongosh --host localhost --port 27017 --username ${MONGODB_INITDB_ROOT_USERNAME} --password ${MONGODB_INITDB_ROOT_PASSWORD} --authenticationDatabase admin --eval "
const adminDb = db.getSiblingDB('admin');
const mongotPassword = '${MONGODB_MONGOTUSER_PASSWORD}';
try {
  adminDb.createUser({
    user: 'mongotUser',
    pwd: mongotPassword,
    roles: [
      { role: 'searchCoordinator', db: 'admin' }
    ]
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

# Load sample data
echo "Loading sample data..."
if [ -f "/sampledata.archive" ]; then
    mongorestore --archive=/sampledata.archive --authenticationDatabase admin -u "${MONGODB_INITDB_ROOT_USERNAME}" -p "${MONGODB_INITDB_ROOT_PASSWORD}"
    echo "Sample data restored successfully."
else
    echo "Warning: sampledata.archive not found"
fi

echo "MongoDB initialization completed successfully."
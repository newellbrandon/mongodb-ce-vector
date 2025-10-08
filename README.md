# [Deploy MongoDB Community with Vector Search via Docker](https://www.mongodb.com/docs/atlas/atlas-vector-search/tutorials/vector-search-quick-start/?deployment-type=self)
https://www.mongodb.com/docs/atlas/atlas-vector-search/tutorials/vector-search-quick-start/?deployment-type=self

## Setup

Run these commands to create the sampledata, keyfile, pwfile, and `.env` file:

```bash
# Download `sampledata.archive`
curl https://atlas-education.s3.amazonaws.com/sampledata.archive -o sampledata.archive

# Create keyfile for replica set
openssl rand -base64 756 > rs0.key

# Create pwfile for mongot authentication
echo -n "password123" > pwfile

# Set secure permissions
chmod 400 rs0.key pwfile

# Create .env file with MongoDB credentials
cat > .env << 'EOF'
# MongoDB Environment Variables
MONGODB_INITDB_ROOT_USERNAME=admin
MONGODB_INITDB_ROOT_PASSWORD=password123
# Must match `pwfile` password
MONGODB_MONGOTUSER_PASSWORD=password123
EOF
```

### Successful creation of files 
```bash
├── .env # <- NEW
├── .gitignore
├── docker-compose.yml
├── init-mongo.sh
├── mongod.conf
├── mongot.conf
├── pwfile # <- NEW
├── README.md
├── rs0.key # <- NEW
├── sampledata.archive # <- NEW
├── vector-index.js
└── vector-query.js


## Running the Environment

Start the MongoDB Community Edition with Vector Search:

```bash
# Start the services in detached mode
docker compose up -d

# View logs to monitor startup
docker compose logs -f
```

Wait for the services to fully start up. You should see messages indicating that the replica set is initialized and mongot is ready.

## Creating the Vector Index

Connect to MongoDB and create the vector search index:

```bash
# Connect to MongoDB as admin user
mongosh "mongodb://admin:password123@localhost:27017/?authSource=admin"

# Switch to the sample_mflix database
use sample_mflix

# Load and execute the vector index creation script
load("vector-index.js")
```

This will create a vector search index named `vector_index` on the `embedded_movies` collection.

## Running Vector Search Queries

Execute the vector search query to find movies similar to "time travel":

```bash
# Load and execute the vector query script
load("vector-query.js")
```

This will search for movies with plots similar to "time travel" using the vector embeddings and return the top 10 most similar results with their similarity scores.

## Tearing Down the Environment

To stop and clean up the environment:

```bash
# Stop the services
docker compose down

# Remove orphaned volumes (WARNING: this will delete all data)
docker compose down -v
```

**Warning**: The `-v` flag will remove all data volumes, including the sample data. Use `docker compose down` without `-v` if you want to preserve the data for future use.
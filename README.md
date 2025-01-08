# Pool Match & Tournament Manager
This application is a service where users can schedule pool matches, track ongoing games and record results. It uses Ruby, SQLite and direct SQL queries.

## Requierements 
- Ruby (version >= 3.1.0)
- SQLite3

## Setup Instructions 
### 1. Clone the Repository
```bash
git clone https://github.com/nickyczeme/pool_match_tournament/
cd pool_match_tournament
```
### 2. Install dependecies
```bash
bundle install
```
### 3. Configure databases

This project uses two databases:
- ```development.sqlite3``` for development
  - To setup the development database:  ```ruby setup-db.rb ```
- ```test.sqlite3``` for testing
  - To setup the test database:  ```ruby setup-db.rb db/test.sqlite3```

### 4. Start the application 
```bash
rails server
```
Server available at ```http://localhost:3000```

## Testing 
To run the tests run: 
```bash
rails test
```

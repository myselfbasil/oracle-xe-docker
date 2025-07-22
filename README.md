# Oracle Database XE with SQL*Plus - Docker Setup

A complete Docker-based Oracle Database Express Edition (XE) 21c with SQL*Plus, featuring cross-platform support and interactive setup. This project provides an easy way to get Oracle Database running locally for development and learning purposes.

## Quick Start

### Installation

**Mac/Linux:**
```bash
./install.sh
```

**Windows:**
```bash
install.bat
```

The installation script will guide you through:
- Creating your database administrator account
- Setting up an application user for development
- Choosing your database name
- Configuring the Oracle database

### Daily Usage

**Mac/Linux:**
```bash
./run.sh
```

**Windows:**
```bash
run.bat
```

This opens an interactive menu to start, stop, and connect to your database.

## What You Get

- **Oracle Database XE 21c** - Full Oracle database for development
- **SQL*Plus** - Oracle's command-line interface
- **Custom Users** - Your own admin and application users
- **Web Interface** - Enterprise Manager Express at https://localhost:5500/em
- **Data Persistence** - Your data survives container restarts
- **Cross-Platform** - Works on Windows, Mac (Intel/Apple Silicon), and Linux

## System Requirements

- Docker Desktop (latest version)
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space
- Internet connection for initial setup

### Platform Notes

- **Windows x64**: Full Oracle XE support
- **Linux x64**: Full Oracle XE support  
- **Mac Intel**: Full Oracle XE support
- **Mac Apple Silicon**: Compatible mode with SQL learning environment

## First Time Setup

1. **Run the installer** using the command above for your platform
2. **Create your admin user** when prompted (this user has full database privileges)
3. **Create your app user** when prompted (this user is for development work)
4. **Choose your database name** (this becomes your main database)
5. **Wait for installation** (takes 10-15 minutes for initial Docker image download)
6. **Test the connection** using the interactive login system

## Connecting to Your Database

### Interactive Login
The run script provides a beautiful login interface with multiple options:
- Database Administrator (full privileges)
- Application User (development access)
- SYSDBA (system administration)
- Connection Test

### Direct Connection
```bash
# Connect as your admin user
docker exec -it oracle-xe sqlplus youradmin/yourpassword

# Connect as your app user to your database
docker exec -it oracle-xe sqlplus yourappuser/yourpassword@YOURDPDB
```

### External Applications
Your database is accessible at:
- **Host**: localhost
- **Port**: 1521
- **Service**: XE (for container database) or YOURDBPDB (for your application database)

## Common Commands

```bash
# Start the database
docker start oracle-xe

# Stop the database
docker stop oracle-xe

# Check if database is running
docker ps | grep oracle-xe

# View database logs
docker logs oracle-xe

# Remove everything (careful - this deletes all data)
./uninstall.sh    # Mac/Linux
uninstall.bat     # Windows
```

## File Structure

```
oracle-xe-docker/
├── install.sh          # Mac/Linux installation
├── install.bat         # Windows installation
├── run.sh              # Mac/Linux daily usage
├── run.bat             # Windows daily usage
├── uninstall.sh        # Mac/Linux removal
├── uninstall.bat       # Windows removal
├── Dockerfile          # Container definition
├── entrypoint.sh       # Container startup script
├── scripts/
│   ├── login.sh        # Interactive login system
│   ├── check_health.sh # Health monitoring
│   └── demo.sql        # Sample SQL scripts
└── .oracle_config      # Your database configuration (created during install)
```

## Troubleshooting

### Database Won't Start
```bash
# Check Docker is running
docker info

# Check container status
docker ps -a | grep oracle-xe

# View error logs
docker logs oracle-xe
```

### Can't Connect
- Ensure the container is running: `docker ps | grep oracle-xe`
- Check your username and password in the interactive login
- Try connecting as SYSDBA: `docker exec -it oracle-xe sqlplus / as sysdba`

### Performance Issues
- Increase Docker memory to 4GB+ in Docker Desktop settings
- Ensure you have sufficient disk space
- Close other memory-intensive applications

### Port Conflicts
If port 1521 is already in use:
```bash
# Check what's using the port
lsof -i :1521          # Mac/Linux
netstat -an | find "1521"    # Windows

# Stop any existing Oracle services
```

### Reset Everything
If you need to start fresh:
```bash
./uninstall.sh    # Mac/Linux
uninstall.bat     # Windows
```
Then run the installer again.

## Web Interface

Once your database is running, you can access the web-based Enterprise Manager Express:
- URL: https://localhost:5500/em
- Login with your admin username and password
- Ignore SSL certificate warnings (it's running locally)

## Learning SQL

The database comes with sample tables and data. Try these commands in SQL*Plus:

```sql
-- Show current user
SELECT USER FROM DUAL;

-- Show current date
SELECT SYSDATE FROM DUAL;

-- List your tables
SELECT table_name FROM user_tables;

-- Create a simple table
CREATE TABLE my_test (id NUMBER, name VARCHAR2(50));

-- Insert some data
INSERT INTO my_test VALUES (1, 'Hello Oracle');

-- Query your data
SELECT * FROM my_test;

-- Exit SQL*Plus
EXIT;
```

## Development Tips

1. **Use the PDB**: Connect to your custom database (YOURDBPDB) for application development
2. **Save your work**: Use COMMIT; to save your changes permanently
3. **Backup important data**: Export your schemas before making major changes
4. **Use the web interface**: Great for visual database management and monitoring

## Security Notes

- Your database passwords are stored securely in `.oracle_config`
- The database only accepts connections from localhost by default
- Change default passwords before using in any production-like environment
- The web interface uses HTTPS but with a self-signed certificate

## Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. View container logs: `docker logs oracle-xe`
3. Ensure you meet the system requirements
4. Try the reset procedure if all else fails

## What's Different About This Setup

- **No default passwords**: You create your own secure credentials
- **Interactive login**: Beautiful terminal interface for connecting
- **Custom database names**: Your database, your name
- **Cross-platform**: Same experience on Windows, Mac, and Linux
- **Apple Silicon support**: Special compatibility mode for M1/M2 Macs
- **Beginner friendly**: Step-by-step guidance throughout

This setup is perfect for learning Oracle SQL, developing applications, or practicing database administration in a safe, local environment.

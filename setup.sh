#!/bin/bash
user=$HOME
sqldir=telemetry/sql
pydir=telemetry/py
db=$user/telemetry/sql/telemetry_factory.db
conf=$user/telemetry/conf.json

sudo apt update && sudo apt -y upgrade
echo "[Device] npm install better-sqlite3..."
npm install better-sqlite3 --prefix  ~/.node-red/
echo "[Device] npm install python library..."
sudo pip3 install sqlalchemy
sudo pip3 install requests

if [ ! -d "$sqldir" ]; then
  mkdir -p $sqldir
  echo "Create Sqlite Directory..."
  if [ ! -f "$db" ]; then
    sqlite3 "$db" "
      CREATE TABLE telemetry_energy_logging(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      create_at DATETIME DEFAULT (datetime('now', '+7 hours')),
      sent INTEGER DEFAULT 0,
      ts INTEGER DEFAULT (unixepoch()),
      date_data TEXT,
      date_time TEXT,
      voltA REAL,
      voltB REAL,
      voltC REAL,
      currentA REAL,
      currentB REAL, 
      currentC REAL,
      powerA REAL,
      powerB REAL,
      powerC REAL,
      powerfA REAL, 
      powerfB REAL, 
      powerfC REAL,
      powerpA REAL, 
      powerpB REAL, 
      powerpC REAL,
      currentpA REAL,
      currentpB REAL,
      currentpC REAL,
      total_e REAL,
      energy_A REAL,
      energy_B REAL,
      co2 REAL
      );"

  sqlite3 "$db" "
      CREATE TABLE telemetry_energy(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      create_at DATETIME DEFAULT (datetime('now', '+7 hours')),
      e0 REAL, 
      e1 REAL, 
      e2 REAL, 
      e3 REAL, 
      e4 REAL, 
      e5 REAL, 
      e6 REAL,
      e7 REAL, 
      e8 REAL, 
      e9 REAL, 
      e10 REAL, 
      e11 REAL, 
      e12 REAL, 
      e13 REAL, 
      e14 REAL, 
      e15 REAL, 
      e16 REAL, 
      e17 REAL, 
      e18 REAL, 
      e19 REAL, 
      e20 REAL, 
      e21 REAL, 
      e22 REAL, 
      e23 REAL
      );"

  sqlite3 "$db" "
     CREATE TABLE telemetry_energy_cloud(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      create_at DATETIME DEFAULT (datetime('now', '+7 hours')),
      sent INTEGER DEFAULT 0,
      ts INTEGER DEFAULT (unixepoch()),
      voltA REAL,
      voltB REAL,
      voltC REAL,
      currentA REAL,
      currentB REAL,
      currentC REAL,
      powerA REAL,
      powerB REAL,
      powerC REAL,
      powerfA REAL,
      powerfB REAL,
      powerfC REAL,
      energy REAL,
      energy_min REAL,
      energy_A REAL,
      energy_B REAL,
      total_energy REAL,
      co2 REAL
      );"
      
    echo "Create DataBase Succesfully..."
  else
    echo "Already has Database..."
  fi
else
  echo "Already has Sqlite Directory..."
fi

if [ ! -d "$pydir" ]; then
  mkdir -p $pydir
  cat << 'EOR' > "$pydir/telemetry_streaming_local.py"
from sqlalchemy import create_engine, Column, Integer, Float, DateTime, Text
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime
import requests
import json
import socket

engine = create_engine("sqlite:////home/orangepi/telemetry/sql/telemetry_factory.db")
Session = sessionmaker(bind=engine)
session = Session()

Base = declarative_base()

class Telemetrylocal(Base):
    __tablename__ = "telemetry_energy_logging"

    id = Column(Integer, primary_key=True)
    create_at = Column(DateTime)
    sent = Column(Integer)
    ts = Column(Integer)
    date_data = Column(Text)
    date_time = Column(Text)
    voltA = Column(Float)
    voltB = Column(Float)
    voltC = Column(Float)
    currentA = Column(Float)
    currentB = Column(Float)
    currentC = Column(Float)
    powerA = Column(Float)
    powerB = Column(Integer)
    powerC = Column(Integer)
    powerfA = Column(Integer)
    powerfB = Column(Float)
    powerfC = Column(Float)
    powerpA = Column(Float)
    powerpB = Column(Float)
    powerpC = Column(Float)
    currentpA = Column(Float)
    currentpB = Column(Float)
    currentpC = Column(Float)
    total_e = Column(Float)
    energy_A = Column(Float)
    energy_B = Column(Float)
    co2 = Column(Float)

class Telemetryenergy(Base):
    __tablename__ = "telemetry_energy"

    id = Column(Integer, primary_key=True)
    create_at = Column(DateTime)
    e0 = Column(Float)
    e1 = Column(Float)
    e2 = Column(Float)
    e3 = Column(Float)
    e4 = Column(Float)
    e5 = Column(Float)
    e6 = Column(Float)
    e7 = Column(Float)
    e8 = Column(Float)
    e9 = Column(Float)
    e10 = Column(Float)
    e11 = Column(Float)
    e12 = Column(Float)
    e13 = Column(Float)
    e14 = Column(Float)
    e15 = Column(Float)
    e16 = Column(Float)
    e17 = Column(Float)
    e18 = Column(Float)
    e19 = Column(Float)
    e20 = Column(Float)
    e21 = Column(Float)
    e22 = Column(Float)
    e23 = Column(Float)

def getLocalIP():
    with open('/tmp/localip/ip.json', 'r', encoding='utf-8') as file:
        data = json.load(file)
        return data["ip"]

def getTelemetry():
    #statements
    _ip = getLocalIP()
    
    lo = session.query(Telemetrylocal)\
        .filter(Telemetrylocal.sent == 0)\
        .order_by(Telemetrylocal.create_at)\
        .first()
    en = session.query(Telemetryenergy)\
        .filter(Telemetryenergy.id == lo.id)\
        .first()
    ts = lo.ts * 1_000
    jsonData = {
            'filesystem': {
                'date': lo.date_data,
                'time': lo.date_time,
                'ip': _ip,
                'date_data': lo.date_data,
                'timestamp': ts
                },
            'values':{
                'voltage':{
                    'A': lo.voltA,
                    'B': lo.voltB,
                    'C': lo.voltC,
                    },
                'current':{
                    'A': lo.currentA,
                    'B': lo.currentB,
                    'C': lo.currentC,
                    },
                'power':{
                    'A': lo.powerA,
                    'B': lo.powerB,
                    'C': lo.powerC,
                    },
                'powerfactor':{
                    'A': lo.powerfA,
                    'B': lo.powerfB,
                    'C': lo.powerfC,
                    },
                'percentagekwh':{
                    'A': lo.powerpA,
                    'B': lo.powerpB,
                    'C': lo.powerpC,
                    },    
                'percentageAmp':{
                    'A': lo.currentpA,
                    'B': lo.currentpB,
                    'C': lo.currentpC,
                    },
                'energy':{
                    '0':en.e0,'1':en.e1,'2':en.e2,'3':en.e3,'4':en.e4,
                    '5':en.e5,'6':en.e6,'7':en.e7,'8':en.e8,'9':en.e9,
                    '10':en.e10,'11':en.e11,'12':en.e12,'13':en.e13,'14':en.e14,'15':en.e15,
                    '16':en.e16,'17':en.e17,'18':en.e18,'19':en.e19,'20':en.e20,
                    '21':en.e21,'22':en.e22,'23':en.e23
                    },
                'total':{
                    'energy':lo.total_e,
                    'energy_A':lo.energy_A,
                    'energy_B':lo.energy_B,
                    'co2':lo.co2
                     
                    }
                }
            }

    return jsonData

def httpRequests(payload):
    source = 1
    url = f"http://192.168.0.9:1880/api/pw-meter/device-opi-source{source}/data-log"
    data = payload
    try:
        response = requests.post(url, json=data, timeout=5)
        
        if  response.ok:
                lo = session.query(Telemetrylocal)\
                .filter(Telemetrylocal.sent == 0)\
                .order_by(Telemetrylocal.create_at)\
                .first()
                lo.sent = 1
                session.commit()
                print(f"ID: {lo.id}")
        else:
            print(response.status_code)
            print(response.json())
        #print(payload)
            
    except requests.exceptions.Timeout:
        print("เซิร์ฟเวอร์ตอบกลับช้าเกินไป (Timeout)")

    except Exception as e:
        print(f"!!!Error: {e}")

httpRequests(getTelemetry())
#print(getTelemetry())
EOR
  cat << 'EOQ' > "$pydir/telemetry_streaming_cloud.py"
from sqlalchemy import create_engine, Column, Integer, Float, DateTime, Text
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime
import requests
import json

engine = create_engine("sqlite:////home/orangepi/telemetry/sql/telemetry_factory.db")
Session = sessionmaker(bind=engine)
session = Session()

Base = declarative_base()

token = "qaxoBY-KSFAid_8Oy9evQgSiT8Yo3lgXJx6cNzVeD1qNJp0mzNw4SCviq4JQgxi1_VqegXFlca7vndziuhFilg=="
host = "147.50.230.159"
port = "8088"
org = "ack-org"
bucket = "power"
url = "http://" + host + ":" + port + "/api/v2/write"
config_path = "/home/orangepi/telemetry/py/meta.json"
base_path = "/home/orangepi/telemetry/sql/telemetry_factory.db"

class Telemetryenergy(Base):
    __tablename__ = "telemetry_energy_cloud"

    id = Column(Integer, primary_key=True)
    create_at = Column(DateTime)
    sent = Column(Integer)
    ts = Column(Integer)
    voltA = Column(Float)
    voltB = Column(Float)
    voltC = Column(Float)
    currentA = Column(Float)
    currentB = Column(Float)
    currentC = Column(Float)
    powerA = Column(Float)
    powerB = Column(Integer)
    powerC = Column(Integer)
    powerfA = Column(Integer)
    powerfB = Column(Float)
    powerfC = Column(Float)
    energy = Column(Float)
    energy_min = Column(Float)
    total_energy = Column(Float)
    energy_A = Column(Float)
    energy_B = Column(Float)
    co2 = Column(Float)

def getTelemetry():
    #statements
    with open('/home/orangepi/telemetry/conf.json', 'r', encoding='utf-8') as f:
        j = json.load(f)
    machine_type = j["type"]
    machine_sector = j["sector"]
    machine_code = j["code"]
    measurement = "telemetry_powers"
    tags = f"type={machine_type},sector={machine_sector},code={machine_code}"

    lo = session.query(Telemetryenergy)\
        .filter(Telemetryenergy.sent == 0)\
        .order_by(Telemetryenergy.create_at)\
        .first()
    en = session.query(Telemetryenergy)\
        .filter(Telemetryenergy.id == lo.id)\
        .first()

    payload = ",".join([
        f"voltA={lo.voltA}",
        f"voltB={lo.voltB}",
        f"voltC={lo.voltC}",
        f"currentA={lo.currentA}",
        f"currentB={lo.currentB}",
        f"currentC={lo.currentC}",
        f"powerA={lo.powerA}",
        f"powerB={lo.powerB}",
        f"powerC={lo.powerC}",
        f"powerfA={lo.powerfA}",
        f"powerfB={lo.powerfB}",
        f"powerfC={lo.powerfC}",
        f"energy={lo.energy}",
        f"energy_min={lo.energy_min}",
        f"energy_A={lo.energy_A}",
        f"energy_B={lo.energy_B}",
        f"total_energy={lo.total_energy}",
        f"co2={lo.co2}"
        ])
    timestamp = lo.ts * 1_000_000_000
    return f"{measurement},{tags} {payload} {timestamp}"

def httpRequests(payload):
    source = 1 
    params = {
            "org": org,
            "bucket": bucket,
            "precision": "ns"
            }
    headers = {
            "Authorization": f"Token {token}",
            "Content-Type": "text/plain; charset=utf-8"
            }
        #ส่ง requests
    try:
        r = requests.post(url, params=params, headers=headers, data=payload, timeout=10)
        #ตรวจสอบ requests
        if  r.status_code ==204:
                lo = session.query(Telemetryenergy)\
                .filter(Telemetryenergy.sent == 0)\
                .order_by(Telemetryenergy.create_at)\
                .first()
                lo.sent = 1
                session.commit()
                print(f"ID: {lo.id}")
        else:
            print(r.status_code)
            print(r.text)
        #print(payload)
            
    except Exception as e:
        print(f"!err: {e}")

httpRequests(getTelemetry())
EOQ
  echo "Create Python Directory..."
else
  echo "Already has Python Directory..."
fi

if [ ! -f "$conf" ]; then
  touch "$conf"
  code=$(cat $HOME/powermeter/device_code.txt)
  cat << EOY > "$conf"
  {
    "type": "-",
    "sector": "MDB1",
    "code": "$code",
    "source": 1,
    "current_ratio": 1
  }
EOY
fi

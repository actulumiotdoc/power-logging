#!/bin/bash
user=$HOME
sqldir=telemetry/sql
pydir=telemetry/py
db=$user/telemetry/sql/telemetry_factory.db
conf=$user/telemetry/conf.json
flows=$user/.node-red/flows.json

sudo apt update && sudo apt -y upgrade
echo "[Device] npm install better-sqlite3..."
npm install better-sqlite3 --prefix  ~/.node-red/
echo "[Device] npm install sqlalchemy..."
sudo pip3 install sqlalchemy

if [ ! -d "$sqldir" ]; then
  mkdir -p $sqldir
  echo "Create Sqlite Directory..."
  if [ ! -f "$db" ]; then
    sqlite3 "$db" "
    CREATE TABLE telemetry_energy_local (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      create_at DATETIME DEFAULT (datetime('now', '+7 hours')),
      sent INTEGER DEFAULT 0,
      ts INTEGER NOT NULL,
      date_data TEXT,
      time_data TEXT,
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
      energy REAL,
      energy_A REAL,
      energy_B REAL,
      total_energy REAL,
      co2 REAL
      );"

  sqlite3 "$db" "
  CREATE TABLE telemetry_energy_hour (
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
    111 REAL,
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
  CREATE TABLE telemetry_energy_cloud (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    create_at DATETIME DEFAULT (datetime('now', '+7 hours')),
    sent INTEGER DEFAULT 0,
    ts INTEGER NOT NULL,
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
    energy REAL,
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
  cat << 'EOR' > "$pydir/requests_local.py"
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
    __tablename__ = "telemetry_local"

    id = Column(Integer, primary_key=True)
    create_at = Column(DateTime)
    sent = Column(Integer)
    ts = Column(Integer)
    date_data = Column(Text)
    time_data = Column(Text)
    total_meter = Column(Float)
    total_a = Column(Float)
    total_b = Column(Float)
    nta_meter = Column(Float)
    ntb_meter = Column(Float)
    ota_meter = Column(Float)
    otb_meter = Column(Float)
    total_work = Column(Integer)
    work_a = Column(Integer)
    work_b = Column(Integer)
    speed_main = Column(Float)
    speed_take = Column(Float)

class Telemetrymeter(Base):
    __tablename__ = "telemetry_meter"

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

class Telemetrywork(Base):
    __tablename__ = "telemetry_work"

    id = Column(Integer, primary_key=True)
    create_at = Column(DateTime)
    w0 = Column(Float)
    w1 = Column(Float)
    w2 = Column(Float)
    w3 = Column(Float)
    w4 = Column(Float)
    w5 = Column(Float)
    w6 = Column(Float)
    w7 = Column(Float)
    w8 = Column(Float)
    w9 = Column(Float)
    w10 = Column(Float)
    w11 = Column(Float)
    w12 = Column(Float)
    w13 = Column(Float)
    w14 = Column(Float)
    w15 = Column(Float)
    w16 = Column(Float)
    w17 = Column(Float)
    w18 = Column(Float)
    w19 = Column(Float)
    w20 = Column(Float)
    w21 = Column(Float)
    w22 = Column(Float)
    w23 = Column(Float)

def jsonRead(key, path):
    with open(path, 'r', encoding='utf-8') as file:
        data = json.load(file)
        return data[key]

def getLocalIP():
    with open('/tmp/localip/ip.json', 'r', encoding='utf-8') as file:
        data = json.load(file)
        return data["ip"]

def getTelemetry():
    #statements
    _ip = getLocalIP()
    
    tb_local = session.query(Telemetrylocal)\
        .filter(Telemetrylocal.sent == 0)\
        .order_by(Telemetrylocal.create_at)\
        .first()
    tb_meter = session.query(Telemetrymeter)\
        .filter(Telemetrymeter.id == tb_local.id)\
        .first()
    tb_work = session.query(Telemetrywork)\
        .filter(Telemetrywork.id == tb_local.id)\
        .first()

    jsonData = {
            'filesystem': {
                'date': tb_local.date_data,
                'time': tb_local.time_data,
                'ip': _ip,
                'date_data': tb_local.date_data,
                'timestamp': tb_local.ts
                },
            'values':{
                'meter':{
                    '0':tb_meter.m0,'1':tb_meter.m1,'2':tb_meter.m2,'3':tb_meter.m3,'4':tb_meter.m4,
                            '5':tb_meter.m5,'6':tb_meter.m6,'7':tb_meter.m7,'8':tb_meter.m8,'9':tb_meter.m9,
                    '10':tb_meter.m10,'11':tb_meter.m11,'12':tb_meter.m12,'13':tb_meter.m13,'14':tb_meter.m14,'15':tb_meter.m15,
                            '16':tb_meter.m16,'17':tb_meter.m17,'18':tb_meter.m18,'19':tb_meter.m19,'20':tb_meter.m20,
                            '21':tb_meter.m21,'22':tb_meter.m22,'23':tb_meter.m23
                    },
                'working':{
                    '0':tb_work.w0,'1':tb_work.w1,'2':tb_work.w2,'3':tb_work.w3,'4':tb_work.w4,
                            '5':tb_work.w5,'6':tb_work.w6,'7':tb_work.w7,'8':tb_work.w8,'9':tb_work.w9,
                    '10':tb_work.w10,'11':tb_work.w11,'12':tb_work.w12,'13':tb_work.w13,'14':tb_work.w14,'15':tb_work.w15,
                            '16':tb_work.w16,'17':tb_work.w17,'18':tb_work.w18,'19':tb_work.w19,'20':tb_work.w20,
                            '21':tb_work.w21,'22':tb_work.w22,'23':tb_work.w23
                    },
            'total':{
                        'meter':{
                    'total':tb_local.total_meter,
                    'totalA':tb_local.total_a,
                    'totalB':tb_local.total_b,
                    'NLA':tb_local.nta_meter,
                            'NLB':tb_local.ntb_meter,
                    'OTA':tb_local.ota_meter,
                                'OTB':tb_local.otb_meter  
                    },
                'working':{
                    'total':tb_local.total_work,
                    'totalA':tb_local.work_a,
                    'totalB':tb_local.work_b
                    }
                },
            'maintake':{
                    'main':{ 'now': tb_local.speed_main
                        },
                    'take':{ 'now': tb_local.speed_take
                        }
                }
            }
        }
    return jsonData

def httpRequests(payload):
    conf = "/home/orangepi/telemetry/conf.json"
    with open(conf, 'r', encoding='utf-8') as file:
        data = json.load(file)
        s = data["source"]
    url = f"http://192.168.0.9:1880/api/product/device-opi-datasource-{s}"
    data = payload
    try:
        response = requests.post(url, json=data, timeout=5)
        
        if  response.ok:
                tb_local = session.query(Telemetrylocal)\
                .filter(Telemetrylocal.sent == 0)\
                .order_by(Telemetrylocal.create_at)\
                .first()
                tb_local.sent = 1
                session.commit()
                print(f"ID: {tb_local.id}")
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
  cat << 'EOQ' > "$pydir/requests_cloud.py"
from sqlalchemy import create_engine, Column, Integer, Float, DateTime, Text
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime
import requests
import json

engine = create_engine("sqlite:////home/orangepi/telemetry/sql/telemetry_factory.db")
Session = sessionmaker(bind=engine)
session = Session()

Base = declarative_base()

def getGroup():
    with open('/home/orangepi/telemetry/conf.json', 'r', encoding='utf-8') as file:
        data = json.load(file)
        code = data['code']
        group = code[0]
        return group, code

token = "r8RQWM-MB2GpL5cO2sWZrHAfiAmt2i9SSgHdyZO5SevepE_qS1bQz-YZJemp4FHkmUXh59dX7Wzs7_KfSKw6dQ=="
host = "147.50.230.159"
port = "8088"
org = "ack-org"
bucket = "sql-loom_data"
mearsurement = "productions"
tuPle= getGroup()
code = tuPle[1]
group = tuPle[0]
tags = f"sector=Loom,groups={group},device={code}"
url = "http://" + host + ":" + port + "/api/v2/write"

class Telemetrycloud(Base):
    __tablename__ = "telemetry_cloud"

    id = Column(Integer, primary_key=True)
    create_at = Column(DateTime)
    sent = Column(Integer)
    ts = Column(Integer)
    total_meter = Column(Float)
    total_a = Column(Float)
    total_b = Column(Float)
    nta_meter = Column(Float)
    ntb_meter = Column(Float)
    ota_meter = Column(Float)
    otb_meter = Column(Float)
    total_work = Column(Integer)
    work_a = Column(Integer)
    work_b = Column(Integer)
    hour_meter = Column(Float)
    speed_main = Column(Float)
    speed_take = Column(Float)

def jsonRead(key, path):
    with open(path, 'r', encoding='utf-8') as file:
        data = json.load(file)
        return data[key]

def onelineTelemetry(mearsurement, tags):
    tb_cloud = session.query(Telemetrycloud)\
        .filter(Telemetrycloud.sent == 0)\
        .order_by(Telemetrycloud.create_at)\
        .first()

    if tb_cloud is None:
        return None, None  # ไม่มีข้อมูลรอส่ง

    fields = ",".join([
        f"m_h={tb_cloud.hour_meter}",
        f"total_meter={tb_cloud.total_meter}",
        f"totalA={tb_cloud.total_a}",
        f"totalB={tb_cloud.total_b}",
        f"NTA={tb_cloud.nta_meter}",
        f"NTB={tb_cloud.ntb_meter}",
        f"OTA={tb_cloud.ota_meter}",
        f"OTB={tb_cloud.otb_meter}",
        f"main={tb_cloud.speed_main}",
        f"take={tb_cloud.speed_take}"
    ])

    timestamp = tb_cloud.ts * 1_000_000
    #print(f"{mearsurement},{tags} {fields} {timestamp}", tb_cloud.id)
    return f"{mearsurement},{tags} {fields} {timestamp}", tb_cloud.id 


def httpsRequests(mea, tag):
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "text/plain; charset=utf-8"
    }
    params = {
        "org": org,
        "bucket": bucket,
        "precision": "ns"
    }
    try:
        oneline, record_id = onelineTelemetry(mea, tag)

        if oneline is None:
            print("No pending records to send.")
            return

        response = requests.post(url, params=params, headers=headers, data=oneline, timeout=10)
        print(f"response: {response.reason}")

        if response.ok:
            tb_cloud =(
                    session.query(Telemetrycloud)
                    .filter(Telemetrycloud.id == record_id)
                    .first()
                    )
            tb_cloud.sent = 1
            session.commit()
            print(f"ID: {tb_cloud.id}")
        else:
            print(f"Code: {response.status_code}")

    except requests.exceptions.Timeout:
        print("!!!Timeout Err: (Timeout)")
    except Exception as e:
        print(f"!!! http function Error: {e}")

httpsRequests(mearsurement, tags)
EOQ
  echo "Create Python Directory..."
else
  echo "Already has Python Directory..."
fi

if [ ! -f "$conf" ]; then
  touch "$conf"
  code=$(cat $HOME/loom/influxdb/device.txt)
  source_=$(cat $HOME/loom/source.txt)
  cat << EOY > "$conf"
  {
    "code": "$code",
    "source": "$source_",
    "circumferance": 0,
    "gear-ratio": 0
  }
EOY
fi 

#node-red-flow
# rm -rf "$flows"
# cat << 'EON' > "$flows"

# EON

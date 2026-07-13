#!/bin/bash
user=$HOME
sqldir=telemetry/sql
pydir=telemetry/py
db=$user/telemetry/sql/telemetry_factory.db
# conf=$user/telemetry/conf.json
flows=$user/.node-red/flows.json

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
    with open('/home/orangepi/telemetry/conf.json', 'r', encoding='utf-8') as file:
      data = json.load(file)
      source = data['source']
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

# if [ ! -f "$conf" ]; then
#   touch "$conf"
#   code=$(cat $HOME/powermeter/device_code.txt)
#   cat << EOY > "$conf"
#   {
#     "type": "-",
#     "sector": "MDB1",
#     "code": "$code",
#     "source": 1,
#     "current_ratio": 1
#   }
# EOY
# fi 

#node-red-flow
rm -rf "$flows"
cat << 'EON' > "$flows"
[
    {
        "id": "e17edba087392acf",
        "type": "tab",
        "label": "Logging 3.0.1",
        "disabled": false,
        "info": "",
        "env": []
    },
    {
        "id": "df4a94479416f0c4",
        "type": "subflow",
        "name": "Get IP",
        "info": "",
        "category": "Special node",
        "in": [
            {
                "x": 80,
                "y": 80,
                "wires": [
                    {
                        "id": "5198508231fcf8a8"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff6100",
        "icon": "node-red/white-globe.svg",
        "status": {
            "x": 480,
            "y": 60,
            "wires": [
                {
                    "id": "f3b472b4726bfeec",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "13f006802899e0be",
        "type": "subflow",
        "name": "Ping",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "633e9c4b40e42584"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 560,
                "y": 80,
                "wires": [
                    {
                        "id": "c7fcb9a183a78340",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#ffb900",
        "icon": "font-awesome/fa-chain",
        "status": {
            "x": 560,
            "y": 140,
            "wires": [
                {
                    "id": "346948538b2e924a",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "31057fe0b0d4c1ec",
        "type": "subflow",
        "name": "Blink",
        "info": "input\r\n - msg.",
        "category": "Lamp",
        "in": [
            {
                "x": 40,
                "y": 40,
                "wires": [
                    {
                        "id": "db6fc316f972fc7a"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ef42f5",
        "icon": "font-awesome/fa-lightbulb-o"
    },
    {
        "id": "a67f25631bef1988",
        "type": "subflow",
        "name": "Global",
        "info": "",
        "category": "Special node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "59eb51568d8158c9"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#046a3b",
        "icon": "font-awesome/fa-globe",
        "status": {
            "x": 360,
            "y": 80,
            "wires": [
                {
                    "id": "23bad38c2d77961c",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "1406c468fdce7358",
        "type": "subflow",
        "name": "Telegram http",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "62597ed5138d084d"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 480,
                "y": 80,
                "wires": [
                    {
                        "id": "fbda616582fab4cb",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#03befc",
        "icon": "font-awesome/fa-send"
    },
    {
        "id": "e226ede58ea4b202",
        "type": "subflow",
        "name": "Modbus & Alarm",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#6229ff",
        "icon": "node-red/alert.svg",
        "status": {
            "x": 380,
            "y": 220,
            "wires": [
                {
                    "id": "c5418b2844d316d7",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "be61994cf1b15e59",
        "type": "subflow",
        "name": "OnBoard",
        "info": "Input\r\n- current rate (msg.current_rate)\r\n- timestamp (msg.payload)",
        "category": "PowerMeter",
        "in": [],
        "out": [
            {
                "x": 880,
                "y": 300,
                "wires": [
                    {
                        "id": "d2f4ea10d2c07645",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#A6FF00",
        "icon": "font-awesome/fa-tachometer",
        "status": {
            "x": 560,
            "y": 340,
            "wires": [
                {
                    "id": "cf5f8f17bede68ae",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "84cf72481f1ee5df",
        "type": "subflow",
        "name": "conf",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "596bf70f28319fb0"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#34ebdb",
        "icon": "node-red/cog.svg"
    },
    {
        "id": "cb99efbd3383440d",
        "type": "subflow",
        "name": "Dashboard",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff3636",
        "icon": "node-red-contrib-chartjs/pie_chart.png",
        "status": {
            "x": 480,
            "y": 640,
            "wires": [
                {
                    "id": "4e1639b8fbf865ce",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "1299eb1c88f25fdf",
        "type": "group",
        "z": "be61994cf1b15e59",
        "name": "",
        "style": {
            "label": true,
            "stroke": "#0070c0",
            "fill": "#000000",
            "label-position": "n",
            "color": "#3f93cf"
        },
        "nodes": [
            "1de286bd7bfbd561",
            "222972ee3fa6f0a4",
            "757983b8e873e303",
            "f2781d52dda640da",
            "53edeb3ba8bb0310",
            "261d03c3220037d3",
            "d5f29208fb2ffdbc",
            "c4cf777e03bd5e20",
            "21a2903668b1c52a",
            "1eeeb5853645d67e",
            "fad4d424d6f9353a",
            "832eaf2001dc1d9a",
            "779ab53e5e1711fb",
            "4f942a5af741f169",
            "6d3137d34e4c478f",
            "cf5f8f17bede68ae"
        ],
        "x": 44,
        "y": 39,
        "w": 662,
        "h": 342
    },
    {
        "id": "4a03533f0307f7ce",
        "type": "group",
        "z": "e17edba087392acf",
        "name": "System management",
        "style": {
            "stroke": "#ff0000",
            "fill": "#000000",
            "fill-opacity": "0.89",
            "label": true,
            "label-position": "n",
            "color": "#ffC000"
        },
        "nodes": [
            "259aa3f685323a1f",
            "ebd6bc595f799807",
            "137a2ed93b8bc4ba",
            "5c386cb590032884",
            "bffbd696e7e7a1d0",
            "19ec6934475a43f6",
            "b77c666e9450adc3",
            "ebaa3baaf4745b67",
            "42d38ab61e124a52"
        ],
        "x": 74,
        "y": 19,
        "w": 492,
        "h": 162
    },
    {
        "id": "46bfaf6a02f976b1",
        "type": "group",
        "z": "e17edba087392acf",
        "name": "Modbus and SQL management",
        "style": {
            "stroke": "#ff0000",
            "fill": "#000000",
            "fill-opacity": "0.86",
            "label": true,
            "label-position": "n",
            "color": "#ffC000"
        },
        "nodes": [
            "c347e1edd04abde6",
            "7055b8fea6b969b0",
            "11d4094ef1e35e1e",
            "9b59d42b30816dd9",
            "e0ae7c4a96d44ec1",
            "d68b38d28bd387de",
            "811b106f17562478",
            "7d3113f0d1f6fdd4",
            "172b16477f714016",
            "c5fb9ad7e2c125ef",
            "7dc780c084014273",
            "1535ea695344fdc5"
        ],
        "x": 74,
        "y": 199,
        "w": 802,
        "h": 142
    },
    {
        "id": "4f942a5af741f169",
        "type": "junction",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "x": 160,
        "y": 100,
        "wires": [
            [
                "1de286bd7bfbd561",
                "1eeeb5853645d67e"
            ]
        ]
    },
    {
        "id": "291667434678740d",
        "type": "modbus-client",
        "name": "",
        "clienttype": "serial",
        "bufferCommands": true,
        "stateLogEnabled": false,
        "queueLogEnabled": false,
        "failureLogEnabled": true,
        "tcpHost": "127.0.0.1",
        "tcpPort": "502",
        "tcpType": "DEFAULT",
        "serialPort": "/dev/ttyUSB0",
        "serialType": "RTU-BUFFERD",
        "serialBaudrate": "9600",
        "serialDatabits": "8",
        "serialStopbits": "1",
        "serialParity": "none",
        "serialConnectionDelay": "100",
        "serialAsciiResponseStartDelimiter": "0x3A",
        "unit_id": "1",
        "commandDelay": "1",
        "clientTimeout": "1000",
        "reconnectOnTimeout": true,
        "reconnectTimeout": "2000",
        "parallelUnitIdsAllowed": true,
        "showErrors": false,
        "showWarnings": true,
        "showLogs": true
    },
    {
        "id": "d6f3a7fd07525d85",
        "type": "ui-base",
        "name": "Power Meter Box (Dashboard)",
        "path": "/dashboard",
        "appIcon": "",
        "includeClientData": true,
        "acceptsClientConfig": [
            "ui-notification",
            "ui-control"
        ],
        "showPathInSidebar": false,
        "headerContent": "dashboard",
        "navigationStyle": "icon",
        "titleBarStyle": "default",
        "showReconnectNotification": true,
        "notificationDisplayTime": 1,
        "showDisconnectNotification": true
    },
    {
        "id": "c59427563d99903b",
        "type": "ui-theme",
        "name": "ui_template.themes.defaultTheme",
        "colors": {
            "surface": "#2e2e2e",
            "primary": "#0094ce",
            "bgPage": "#2e2e2e",
            "groupBg": "#2e2e2e",
            "groupOutline": "#2e2e2e"
        },
        "sizes": {
            "density": "default",
            "pagePadding": "12px",
            "groupGap": "12px",
            "groupBorderRadius": "4px",
            "widgetGap": "12px"
        }
    },
    {
        "id": "8e3d40d0703d9eb6",
        "type": "ui-page",
        "name": "HOME",
        "ui": "d6f3a7fd07525d85",
        "path": "/config",
        "icon": "home",
        "layout": "tabs",
        "theme": "c59427563d99903b",
        "breakpoints": [
            {
                "name": "Default",
                "px": "0",
                "cols": "3"
            },
            {
                "name": "Tablet",
                "px": "576",
                "cols": "6"
            },
            {
                "name": "Small Desktop",
                "px": "768",
                "cols": "9"
            },
            {
                "name": "Desktop",
                "px": "1024",
                "cols": "12"
            }
        ],
        "order": 1,
        "className": "",
        "visible": "true",
        "disabled": "false"
    },
    {
        "id": "f9f9aa68ad730d89",
        "type": "ui-group",
        "name": "Configuration",
        "page": "8e3d40d0703d9eb6",
        "width": "12",
        "height": 1,
        "order": 1,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "32628e2ce266c618",
        "type": "ui-group",
        "name": "config",
        "page": "8e3d40d0703d9eb6",
        "width": "12",
        "height": 1,
        "order": 2,
        "showTitle": true,
        "className": "",
        "visible": "false",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "e8820b5a1009efdc",
        "type": "ui-group",
        "name": "Local Server Logging",
        "page": "8e3d40d0703d9eb6",
        "width": "12",
        "height": 1,
        "order": 3,
        "showTitle": true,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "eebb29937be17277",
        "type": "ui-group",
        "name": "Cloud Server Logging",
        "page": "8e3d40d0703d9eb6",
        "width": "12",
        "height": 1,
        "order": 4,
        "showTitle": true,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "315e88c2f55060cc",
        "type": "ui-group",
        "name": "Energy Table Local Logging",
        "page": "8e3d40d0703d9eb6",
        "width": 6,
        "height": 1,
        "order": 5,
        "showTitle": true,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "5198508231fcf8a8",
        "type": "exec",
        "z": "df4a94479416f0c4",
        "command": "hostname -I",
        "addpay": false,
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "name": "Fetch IP",
        "x": 200,
        "y": 80,
        "wires": [
            [
                "f3b472b4726bfeec",
                "ce789fc5954b2049"
            ],
            [],
            []
        ]
    },
    {
        "id": "f3b472b4726bfeec",
        "type": "function",
        "z": "df4a94479416f0c4",
        "name": "function 2",
        "func": "let ip = msg.payload.replace(/[\\r\\n\\t ]/g, \"\");\nlet get_ip = global.get(\"config.state.ip\");\n    if((get_ip === undefined && ip) || ip){\n        global.set(\"config.state.ip\", ip);\n    };\nmsg.payload = {\n    fill: \"yellow\",\n    shape: \"ring\",\n    text: `IP:${ip}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 360,
        "y": 60,
        "wires": [
            []
        ]
    },
    {
        "id": "ce789fc5954b2049",
        "type": "function",
        "z": "df4a94479416f0c4",
        "name": "function 8",
        "func": "let ip = msg.payload.replace(/[\\r\\n\\t ]/g, \"\");\n\nmsg.payload = {\n    ip:ip\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 360,
        "y": 100,
        "wires": [
            [
                "780162e582c1ec43"
            ]
        ]
    },
    {
        "id": "780162e582c1ec43",
        "type": "file",
        "z": "df4a94479416f0c4",
        "name": "",
        "filename": "/tmp/localip/ip.json",
        "filenameType": "str",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "none",
        "x": 550,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "633e9c4b40e42584",
        "type": "ping",
        "z": "13f006802899e0be",
        "protocol": "IPv4",
        "mode": "triggered",
        "name": "",
        "host": "",
        "timer": "10",
        "inputs": 1,
        "x": 135,
        "y": 80,
        "wires": [
            [
                "5805fc6c631c073d"
            ]
        ],
        "l": false
    },
    {
        "id": "5805fc6c631c073d",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 684",
        "func": "global.set(\"config.state.online\", (msg.payload) ? true : false);\nmsg.payload = global.get(\"config.state.online\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 80,
        "wires": [
            [
                "c7fcb9a183a78340",
                "346948538b2e924a"
            ]
        ]
    },
    {
        "id": "346948538b2e924a",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 686",
        "func": "var sho2 = `[${global.get(\"config.datetime.time\")}] Gateway:${global.get(\"config.state.online\")}`;\nmsg.payload = {\n    \"fill\": \"blue\",\n    \"shape\": \"dot\",\n    \"text\": sho2\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 140,
        "wires": [
            []
        ]
    },
    {
        "id": "c7fcb9a183a78340",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 687",
        "func": "let c1 = global.get(\"config.state.online\");\nlet stat = flow.get(\"stat\"); // ใช้ตัวแปรใน flow เพื่อเก็บสถานะ\n// ตรวจสอบว่า payload เปลี่ยนแปลงหรือยัง\nif (stat === undefined) {\n    // ถ้ายังไม่มีสถานะเก็บไว้ (สถานะเริ่มต้น)\n    stat = {\n        payload: 1, // ค่าพื้นฐานของ payload\n        isProcessed: false // กำหนดสถานะให้ทำงานได้ครั้งแรก\n    };\n    flow.set(\"stat\", stat); // เก็บสถานะใน flow\n}\n// ตรวจสอบเงื่อนไขที่กำหนด\nif (c1) {\n    if (stat.payload !== 3) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 3;\n        stat.payload = 3; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n} else {\n    if (stat.payload !== 2) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 2;\n        stat.payload = 2; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n}\nflow.set(\"stat\", stat); // อัปเดตสถานะใน flow",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "db6fc316f972fc7a",
        "type": "exec",
        "z": "31057fe0b0d4c1ec",
        "command": "./stat_led/blink.sh",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "WeightScale Ready",
        "x": 115,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ],
        "icon": "node-red/light.svg",
        "l": false
    },
    {
        "id": "59eb51568d8158c9",
        "type": "moment",
        "z": "a67f25631bef1988",
        "name": "",
        "topic": "",
        "input": "",
        "inputType": "date",
        "inTz": "Asia/Bangkok",
        "adjAmount": 0,
        "adjType": "days",
        "adjDir": "add",
        "format": "",
        "locale": "en-US",
        "output": "payload",
        "outputType": "msg",
        "outTz": "Asia/Bangkok",
        "x": 125,
        "y": 80,
        "wires": [
            [
                "23bad38c2d77961c"
            ]
        ],
        "l": false
    },
    {
        "id": "23bad38c2d77961c",
        "type": "function",
        "z": "a67f25631bef1988",
        "name": "function 1",
        "func": "var date = new Date(msg.payload);\nlet previousDate = new Date(date); \n    previousDate.setDate(previousDate.getDate() - 1).toString().padStart(2, 0);\nvar year = date.getFullYear(); \nvar month = (date.getMonth() + 1).toString().padStart(2, '0');\nvar day = date.getDate().toString().padStart(2, '0');\nvar hours = date.getHours().toString().padStart(2, '0');\nvar minutes = date.getMinutes().toString().padStart(2, '0');\nvar seconds = date.getSeconds().toString().padStart(2, '0');\nvar dateMian = `${year}/${month}/${day}`;\nvar time = `${hours}:${minutes}:${seconds}`;\nvar datestamp = global.get(\"config.state.datestamp\");\nlet hoursNum = Number(hours);\n    globalSet();\n////////////////////////////// end function set date ///////////////////////////////////////\nif (hoursNum >= 8 && hoursNum <= 23) {\n    let dateset = filename(date);\n    var datenow = dateNow(date);\n    global.set(\"config.state.date_data\", dateset);\n} else {\n    let dateset = filename(previousDate);\n    var datenow = dateNow(previousDate);\n    global.set(\"config.state.date_data\", dateset);\n}\n\nif (datestamp) {\n    if (datenow != datestamp) {\n        resetValues();\n        // global.set(\"report\", true);\n        // stamp date\n        global.set(\"config.state.datestamp\", datenow);\n    } else {\n        // stamp date\n        global.set(\"config.state.datestamp\", datenow);\n    }\n} else {\n    global.set(\"config.state.datestamp\", datenow);\n}\n    global.set(\"config.state.datenow\", datenow);\n    msg.payload = {\n        fill: \"green\",\n        shape: \"ring\",\n        text: `DATESTAMP:${datestamp} DATE${day}/${month}/${year} TIME:${time}`\n    };\n    return msg;\n\nfunction filename(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}\n\nfunction resetValues(){\n    var energy = new Array(24).fill(0);\n    global.set(\"values.energyh\", energy);\n}\n\nfunction globalSet(){\n    global.set(\"config.datetime.date\", dateMian);\n    global.set(\"config.datetime.day\", day);\n    global.set(\"config.datetime.month\", month);\n    global.set(\"config.datetime.year\", year);\n    global.set(\"config.datetime.time\", time);\n    global.set(\"config.datetime.hour\", hours);\n    global.set(\"config.datetime.minute\", minutes);\n    global.set(\"config.datetime.second\", seconds);\n}\n\nfunction dateNow(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 240,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "fbda616582fab4cb",
        "type": "http request",
        "z": "1406c468fdce7358",
        "name": "",
        "method": "use",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 350,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "62597ed5138d084d",
        "type": "function",
        "z": "1406c468fdce7358",
        "name": "function 10",
        "func": "let botToken = \"8181762860:AAEDyLgCoHmRrZ4nrSxUPYfe2Xsov_mvH3g\";\nlet chatId = \"-4940675177\";\nlet message = msg.payload;\n\nmsg.url = `https://api.telegram.org/bot${botToken}/sendMessage`;\nmsg.method = \"POST\";\nmsg.payload = {\n    chat_id: chatId,\n    text: message\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 180,
        "y": 80,
        "wires": [
            [
                "fbda616582fab4cb"
            ]
        ]
    },
    {
        "id": "698cc965e4a64996",
        "type": "inject",
        "z": "e226ede58ea4b202",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": true,
        "onceDelay": "15",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 135,
        "y": 160,
        "wires": [
            [
                "d1e4489c3e8ca995",
                "c5418b2844d316d7"
            ]
        ],
        "icon": "font-awesome/fa-info-circle",
        "l": false
    },
    {
        "id": "d1e4489c3e8ca995",
        "type": "function",
        "z": "e226ede58ea4b202",
        "name": "function 6",
        "func": "let time_cal = Number(msg.payload - global.get(\"config.modbus.timestamp\"));\nlet count = flow.get(\"count\") || 0;\ntime_cal > 10000 || !global.get(\"config.modbus.timestamp\") ? flow.set(\"count\", count + 1) : flow.set(\"count\", 0); // 3000 millisec\nreturn count > 300 ? msg : undefined;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 260,
        "y": 160,
        "wires": [
            [
                "ce2564d1100f0cb3"
            ]
        ]
    },
    {
        "id": "c5418b2844d316d7",
        "type": "function",
        "z": "e226ede58ea4b202",
        "name": "function 7",
        "func": "let count = flow.get(\"count\")\nmsg.count = count\nmsg.payload = {\n    fill: count < 1? \"green\" : \"red\",\n    shape: count < 1? \"dot\" : \"ring\",\n    text: count\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 280,
        "y": 220,
        "wires": [
            [
                "b20e01c67a28eeb6"
            ]
        ]
    },
    {
        "id": "9eb83d2ca8ce536d",
        "type": "exec",
        "z": "e226ede58ea4b202",
        "command": "reboot",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 650,
        "y": 160,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "09af4c1ad37430eb",
        "type": "exec",
        "z": "e226ede58ea4b202",
        "command": "./stat_led/modbus_err.sh",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "blink err",
        "x": 560,
        "y": 280,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "b20e01c67a28eeb6",
        "type": "switch",
        "z": "e226ede58ea4b202",
        "name": "",
        "property": "count",
        "propertyType": "msg",
        "rules": [
            {
                "t": "gt",
                "v": "0",
                "vt": "num"
            }
        ],
        "checkall": "true",
        "repair": false,
        "outputs": 1,
        "x": 410,
        "y": 280,
        "wires": [
            [
                "09af4c1ad37430eb"
            ]
        ]
    },
    {
        "id": "4bcac64d1b91385f",
        "type": "subflow:1406c468fdce7358",
        "z": "e226ede58ea4b202",
        "name": "",
        "x": 500,
        "y": 160,
        "wires": [
            [
                "9eb83d2ca8ce536d"
            ]
        ]
    },
    {
        "id": "ce2564d1100f0cb3",
        "type": "function",
        "z": "e226ede58ea4b202",
        "name": "function 11",
        "func": "let wot = flow.get(\"wot\");\nif (!wot) {\n    msg.payload = `❗⛓️‍💥 ${global.get(\"config.state.ip\")} > การส่งข้อมูลของ Converter RS485 อาจมีปัญหา...`;\n    node.status({ fill: \"green\", shape: \"ring\", text: global.get(\"time\") });\n    flow.set(\"wot\", true);\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 375,
        "y": 160,
        "wires": [
            [
                "4bcac64d1b91385f"
            ]
        ],
        "l": false
    },
    {
        "id": "1de286bd7bfbd561",
        "type": "modbus-getter",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "InputRegister",
        "adr": "0",
        "quantity": "10",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 260,
        "y": 120,
        "wires": [
            [
                "222972ee3fa6f0a4",
                "d5f29208fb2ffdbc"
            ],
            []
        ]
    },
    {
        "id": "222972ee3fa6f0a4",
        "type": "modbus-response",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "registerShowMax": 20,
        "x": 450,
        "y": 100,
        "wires": []
    },
    {
        "id": "757983b8e873e303",
        "type": "modbus-getter",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "2",
        "dataType": "InputRegister",
        "adr": "0",
        "quantity": "10",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 260,
        "y": 200,
        "wires": [
            [
                "f2781d52dda640da",
                "c4cf777e03bd5e20"
            ],
            []
        ]
    },
    {
        "id": "f2781d52dda640da",
        "type": "modbus-response",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "registerShowMax": 20,
        "x": 450,
        "y": 180,
        "wires": []
    },
    {
        "id": "53edeb3ba8bb0310",
        "type": "modbus-getter",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "3",
        "dataType": "InputRegister",
        "adr": "0",
        "quantity": "10",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 260,
        "y": 280,
        "wires": [
            [
                "261d03c3220037d3",
                "21a2903668b1c52a",
                "cf5f8f17bede68ae"
            ],
            []
        ]
    },
    {
        "id": "261d03c3220037d3",
        "type": "modbus-response",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "registerShowMax": 20,
        "x": 450,
        "y": 260,
        "wires": []
    },
    {
        "id": "d5f29208fb2ffdbc",
        "type": "function",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "function 659",
        "func": "const current_rate = global.get(\"config.state.current_ratio\") || 1;\nconst plase = 'A';\n//voltage\nflow.set(`voltage${plase}`, msg.payload[0] / 10);\n//current\nconst current = Math.trunc((((msg.payload[2] << 16 | msg.payload[1]) * current_rate) * 0.001) * 100) / 100; // 0.001=Amp\nflow.set(`current${plase}`, current);\n//power\nconst power = Math.trunc((((msg.payload[4] << 16 | msg.payload[3]) * current_rate) * 0.001) * 100) / 100; // 0.1=W, 0.001=kW\nflow.set(`power${plase}`, power);\n//energy\nconst energy = Math.trunc((((msg.payload[6] << 16 | msg.payload[5]) * current_rate) * 0.001) * 100) / 100; // 1=Wh, 0.001 = kWh\nflow.set(`energy${plase}`, energy);\n//powerfactor\nvar power_factorA = Math.trunc((msg.payload[8] * 0.01) * 100) / 100;\nflow.set(`powerfactor${plase}`, power_factorA);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 140,
        "wires": [
            [
                "779ab53e5e1711fb"
            ]
        ]
    },
    {
        "id": "c4cf777e03bd5e20",
        "type": "function",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "function 660",
        "func": "const current_rate = global.get(\"config.state.current_ratio\") || 1;\nconst plase = 'B';\n//voltage\nflow.set(`voltage${plase}`, msg.payload[0] / 10);\n//current\nconst current = Math.trunc((((msg.payload[2] << 16 | msg.payload[1]) * current_rate) * 0.001) * 100) / 100; // 0.001=Amp\nflow.set(`current${plase}`, current);\n//power\nconst power = Math.trunc((((msg.payload[4] << 16 | msg.payload[3]) * current_rate) * 0.001) * 100) / 100; // 0.1=W, 0.001=kW\nflow.set(`power${plase}`, power);\n//energy\nconst energy = Math.trunc((((msg.payload[6] << 16 | msg.payload[5]) * current_rate) * 0.001) * 100) / 100; // 1=Wh, 0.001 = kWh\nflow.set(`energy${plase}`, energy);\n//powerfactor\nvar power_factorA = Math.trunc((msg.payload[8] * 0.01) * 100) / 100;\nflow.set(`powerfactor${plase}`, power_factorA);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 220,
        "wires": [
            [
                "832eaf2001dc1d9a"
            ]
        ]
    },
    {
        "id": "21a2903668b1c52a",
        "type": "function",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "function 661",
        "func": "const current_rate = global.get(\"config.state.current_ratio\") || 1;\nconst plase = 'C';\n//voltage\nflow.set(`voltage${plase}`, msg.payload[0] / 10);\n//current\nconst current = Math.trunc((((msg.payload[2] << 16 | msg.payload[1]) * current_rate) * 0.001) * 100) / 100; // 0.001=Amp\nflow.set(`current${plase}`, current);\n//power\nconst power = Math.trunc((((msg.payload[4] << 16 | msg.payload[3]) * current_rate) * 0.001) * 100) / 100; // 0.1=W, 0.001=kW\nflow.set(`power${plase}`, power);\n//energy\nconst energy = Math.trunc((((msg.payload[6] << 16 | msg.payload[5]) * current_rate) * 0.001) * 100) / 100; // 1=Wh, 0.001 = kWh\nflow.set(`energy${plase}`, energy);\n//powerfactor\nvar power_factorA = Math.trunc((msg.payload[8] * 0.01) * 100) / 100;\nflow.set(`powerfactor${plase}`, power_factorA);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 300,
        "wires": [
            [
                "fad4d424d6f9353a"
            ]
        ]
    },
    {
        "id": "1eeeb5853645d67e",
        "type": "function",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "timestamp",
        "func": "flow.set(\"timestamp\", msg.payload);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\nflow.set(\"current_rate\", global.get(\"config.state.cur_ratio\") || 1)",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "fad4d424d6f9353a",
        "type": "function",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "function 662",
        "func": "var voltA = flow.get(\"voltageA\");\nvar voltB = flow.get(\"voltageB\");\nvar voltC = flow.get(\"voltageC\");\n\nvar currentA = flow.get(\"currentA\");\nvar currentB = flow.get(\"currentB\");\nvar currentC = flow.get(\"currentC\");\n\nvar powerA = flow.get(\"powerA\");\nvar powerB = flow.get(\"powerB\");\nvar powerC = flow.get(\"powerC\");\n\nvar energyA = flow.get(\"energyA\");\nvar energyB = flow.get(\"energyB\");\nvar energyC = flow.get(\"energyC\");\n\nvar powerfactorA = flow.get(\"powerfactorA\");\nvar powerfactorB = flow.get(\"powerfactorB\");\nvar powerfactorC = flow.get(\"powerfactorC\");\n\nvar timestamp_res = flow.get(\"timestamp\");\nvar percentage_powerA, percentage_powerB, percentage_powerC;\nvar percentage_currentA, percentage_currentB, percentage_currentC;\n\nvar total_power = Math.trunc((powerA + powerB + powerC) * 100) / 100;\nif (powerA && powerB && powerC) {\n    percentage_powerA = Math.trunc((powerA / total_power * 100) * 100) / 100;\n    percentage_powerB = Math.trunc((powerB / total_power * 100) * 100) / 100;\n    percentage_powerC = Math.trunc((powerC / total_power * 100) * 100) / 100;\n} else {\n    percentage_powerA = 0;\n    percentage_powerB = 0;\n    percentage_powerC = 0;\n}\n\nvar total_current = Math.trunc((currentA + currentB + currentC) * 100) / 100;\nif (currentA && currentB && currentC) {\n    percentage_currentA = Math.trunc((currentA / total_current * 100) * 100) / 100;\n    percentage_currentB = Math.trunc((currentB / total_current * 100) * 100) / 100;\n    percentage_currentC = Math.trunc((currentC / total_current * 100) * 100) / 100;\n} else {\n    percentage_currentA = 0;\n    percentage_currentB = 0;\n    percentage_currentC = 0;\n}\n\nvar energy_stack = Math.trunc((energyA + energyB + energyC) * 100) / 100;\nvar timestamp = flow.get(\"timestamp\")\n\nmsg.payload = {\n    'ts': timestamp,\n    'volt': {\n        'A': voltA,\n        'B': voltB,\n        'C': voltC\n    },\n    'current': {\n        'A': currentA,\n        'B': currentB,\n        'C': currentC\n    },\n    'power': {\n        'A': powerA,\n        'B': powerB,\n        'C': powerC\n    },\n    'energy': {\n        'A': energyA,\n        'B': energyB,\n        'C': energyC\n    },\n    'powerfactor': {\n        'A': powerfactorA,\n        'B': powerfactorB,\n        'C': powerfactorC\n    },\n    'percentage': {\n        'power': {\n            'A': percentage_powerA,\n            'B': percentage_powerB,\n            'C': percentage_powerC\n        },\n        'current': {\n            'A': percentage_currentA,\n            'B': percentage_currentB,\n            'C': percentage_currentC\n        }\n    },\n    'total': {\n        'energy_stack': energy_stack,\n        'power': total_power,\n        'current': total_current,\n    }\n}\nmsg.val32 = flow.get(\"val32\");\nmsg.pp = flow.get(\"pp\");\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 610,
        "y": 300,
        "wires": [
            [
                "d2f4ea10d2c07645"
            ]
        ]
    },
    {
        "id": "832eaf2001dc1d9a",
        "type": "delay",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 145,
        "y": 260,
        "wires": [
            [
                "53edeb3ba8bb0310"
            ]
        ],
        "l": false
    },
    {
        "id": "779ab53e5e1711fb",
        "type": "delay",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 145,
        "y": 180,
        "wires": [
            [
                "757983b8e873e303"
            ]
        ],
        "l": false
    },
    {
        "id": "6d3137d34e4c478f",
        "type": "inject",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": true,
        "onceDelay": "10",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 105,
        "y": 100,
        "wires": [
            [
                "4f942a5af741f169"
            ]
        ],
        "l": false
    },
    {
        "id": "d2f4ea10d2c07645",
        "type": "function",
        "z": "be61994cf1b15e59",
        "name": "values",
        "func": "let payload = msg.payload\n    // timestamp\n    global.set(\"config.modbus.timestamp\", payload.ts);\n    // volt\n    global.set(\"values.voltage.A\", payload.volt.A);\n    global.set(\"values.voltage.B\", payload.volt.B);\n    global.set(\"values.voltage.C\", payload.volt.C);\n    // powerfactor\n    global.set(\"values.powerfactor.A\", payload.powerfactor.A);\n    global.set(\"values.powerfactor.B\", payload.powerfactor.B);\n    global.set(\"values.powerfactor.C\", payload.powerfactor.C);\n    // percentage\n    global.set(\"values.percentage.power.A\", payload.percentage.power.A);\n    global.set(\"values.percentage.power.B\", payload.percentage.power.B);\n    global.set(\"values.percentage.power.C\", payload.percentage.power.C);\n    global.set(\"values.percentage.current.A\", payload.percentage.current.A);\n    global.set(\"values.percentage.current.B\", payload.percentage.current.B);\n    global.set(\"values.percentage.current.C\", payload.percentage.current.C);\n    // current\n    global.set(\"values.current.A\", payload.current.A);\n    global.set(\"values.current.B\", payload.current.B);\n    global.set(\"values.current.C\", payload.current.C);\n    global.set(\"values.current.total\", payload.total.current);\n    // power\n    global.set(\"values.power.A\", payload.power.A);\n    global.set(\"values.power.B\", payload.power.B);\n    global.set(\"values.power.C\", payload.power.C);\n    global.set(\"values.power.total\", payload.total.power);\n    // energy\n    global.set(\"values.enStack.A\", payload.energy.A);\n    global.set(\"values.enStack.B\", payload.energy.B);\n    global.set(\"values.enStack.C\", payload.energy.C);\n    global.set(\"values.total.enstack\", payload.total.energy_stack);\n    global.set(\"values.total.total_power\", payload.total.total_power);\n    global.set(\"values.total.total_current\", payload.total.total_current);\n    msg.payload = flow.get(\"timestamp\");\n    node.status({fill:\"blue\",shape:\"dot\",text:global.get(\"config.datetime.time\")});\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 770,
        "y": 300,
        "wires": [
            []
        ]
    },
    {
        "id": "cf5f8f17bede68ae",
        "type": "function",
        "z": "be61994cf1b15e59",
        "g": "1299eb1c88f25fdf",
        "name": "function 20",
        "func": "msg.payload = {\n    'fill': 'blue',\n    'shape': 'dot',\n    'text': `${flow.get(\"timestamp\")}`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 340,
        "wires": [
            []
        ]
    },
    {
        "id": "596bf70f28319fb0",
        "type": "file in",
        "z": "84cf72481f1ee5df",
        "name": "json",
        "filename": "/home/orangepi/telemetry/conf.json",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 190,
        "y": 80,
        "wires": [
            [
                "0188349d056ec519"
            ]
        ]
    },
    {
        "id": "0188349d056ec519",
        "type": "function",
        "z": "84cf72481f1ee5df",
        "name": "conf",
        "func": "const item = JSON.parse(msg.payload);\nglobal.set(\"config.state.source\", item.source);\nglobal.set(\"config.state.current_ratio\", item.current_ratio);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "28bfd84cc4674302",
        "type": "file in",
        "z": "cb99efbd3383440d",
        "name": "json",
        "filename": "/home/orangepi/telemetry/conf.json",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 330,
        "y": 140,
        "wires": [
            [
                "5b66713f05369916"
            ]
        ]
    },
    {
        "id": "f2c794b7c5f3357b",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "json",
        "func": "const item = JSON.parse(msg.payload);\nflow.set(\"code\", item.code);\nflow.set(\"source\", item.source);\nflow.set(\"current_ratio\", item.current_ratio);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 530,
        "y": 140,
        "wires": [
            [
                "d0bd01dc46030ae0"
            ]
        ]
    },
    {
        "id": "d0bd01dc46030ae0",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "function 17",
        "func": "msg.ui_update = {\n    'label': `ตั้งค่าอัตราส่วนกระแสไฟฟ้า: ${flow.get(\"current_ratio\")}00 AMP`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 690,
        "y": 140,
        "wires": [
            [
                "cab5492a4e6b926c"
            ]
        ]
    },
    {
        "id": "5b66713f05369916",
        "type": "delay",
        "z": "cb99efbd3383440d",
        "name": "",
        "pauseType": "delay",
        "timeout": "500",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 435,
        "y": 140,
        "wires": [
            [
                "f2c794b7c5f3357b"
            ]
        ],
        "l": false
    },
    {
        "id": "cab5492a4e6b926c",
        "type": "ui-form",
        "z": "cb99efbd3383440d",
        "name": "",
        "group": "32628e2ce266c618",
        "label": "ตั้งค่าอัตราส่วนกระแสไฟฟ้า",
        "order": 1,
        "width": "4",
        "height": "4",
        "options": [
            {
                "label": "Current Ratio",
                "key": "curratio",
                "type": "dropdown",
                "required": false,
                "rows": null
            }
        ],
        "formValue": {
            "curratio": ""
        },
        "payload": "",
        "submit": "submit",
        "cancel": "clear",
        "resetOnSubmit": true,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": "",
        "className": "",
        "passthru": false,
        "dropdownOptions": [
            {
                "dropdown": "curratio",
                "value": "1",
                "label": "100 AMP"
            },
            {
                "dropdown": "curratio",
                "value": "3",
                "label": "300 AMP"
            },
            {
                "dropdown": "curratio",
                "value": "5",
                "label": "500 AMP"
            }
        ],
        "x": 910,
        "y": 140,
        "wires": [
            [
                "f11b32da1163c2b9"
            ]
        ]
    },
    {
        "id": "f11b32da1163c2b9",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "function 18",
        "func": "msg.payload = `{\n    \"code\": \"${flow.get(\"code\")}\",\n    \"source\": \"${flow.get(\"source\")}\",\n    \"current_ratio\": ${msg.payload.curratio},\n}\n`\nglobal.set(\"config.state.current_ratio\", msg.payload.curratio)\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1130,
        "y": 140,
        "wires": [
            [
                "e0b00a3486068c86"
            ]
        ]
    },
    {
        "id": "e0b00a3486068c86",
        "type": "file",
        "z": "cb99efbd3383440d",
        "name": "json",
        "filename": "/home/orangepi/telemetry/conf.json",
        "filenameType": "str",
        "appendNewline": true,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 1290,
        "y": 140,
        "wires": [
            []
        ]
    },
    {
        "id": "43e0c4a8a7e64030",
        "type": "exec",
        "z": "cb99efbd3383440d",
        "command": "reboot",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 285,
        "y": 200,
        "wires": [
            [],
            [],
            []
        ],
        "l": false
    },
    {
        "id": "cdb805d5dd3bc03e",
        "type": "ui-button",
        "z": "cb99efbd3383440d",
        "group": "32628e2ce266c618",
        "name": "",
        "label": "Reboot",
        "order": 3,
        "width": "1",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "power",
        "iconPosition": "left",
        "payload": "reboot",
        "payloadType": "str",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "#eb4034",
        "textColor": "#3434eb",
        "iconColor": "#3434eb",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 160,
        "y": 200,
        "wires": [
            [
                "43e0c4a8a7e64030"
            ]
        ]
    },
    {
        "id": "d322bbbf1a61f51c",
        "type": "ui-button",
        "z": "cb99efbd3383440d",
        "group": "32628e2ce266c618",
        "name": "",
        "label": "Refresh",
        "order": 2,
        "width": "1",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "arrow-down-circle",
        "iconPosition": "left",
        "payload": "",
        "payloadType": "date",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "#45d428",
        "textColor": "#f0f6ff",
        "iconColor": "#f0f6ff",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 160,
        "y": 140,
        "wires": [
            [
                "28bfd84cc4674302"
            ]
        ]
    },
    {
        "id": "d0c4f2140cb331e6",
        "type": "ui-button",
        "z": "cb99efbd3383440d",
        "group": "32628e2ce266c618",
        "name": "",
        "label": "Emtry",
        "order": 4,
        "width": "1",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "null",
        "iconPosition": "right",
        "payload": "reboot",
        "payloadType": "str",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "#949494",
        "textColor": "#4a4949",
        "iconColor": "#4a4949",
        "enableClick": false,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 150,
        "y": 320,
        "wires": [
            []
        ]
    },
    {
        "id": "e48a532fe61521e9",
        "type": "inject",
        "z": "cb99efbd3383440d",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "60",
        "crontab": "",
        "once": true,
        "onceDelay": "59",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 170,
        "y": 380,
        "wires": [
            [
                "5389801410e647ea",
                "fc08a412b31ddf32",
                "b3aef1aea38a6066",
                "71670ab740b25226",
                "3657f16d74d9481e",
                "bdb4b4beaeabc1e1",
                "4e1639b8fbf865ce"
            ]
        ]
    },
    {
        "id": "5389801410e647ea",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "SELECT Local",
        "func": "const db = context.get(\"db\");\ntry{\n        const item = db.prepare(`\n        SELECT id, create_at, sent, total_e, energy_A, energy_B, co2 \n        FROM telemetry_energy_logging\n        ORDER BY create_at DESC\n        LIMIT 10;\n        `).all();\n        msg.payload = item;\n        return msg;\n    } catch (err) {\n        node.error(err);\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\n// const Database = require('better-sqlite3');\ncontext.set(\"db\", new Database('/home/orangepi/telemetry/sql/telemetry_factory.db'));",
        "finalize": "// Code added here will be run when the\n// node is being stopped or re-deployed.\nconst db = context.get(\"db\");\nif (db) db.close();",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 360,
        "y": 380,
        "wires": [
            [
                "2d1b654aad918e8c"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "fc08a412b31ddf32",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "SELECT Cloud",
        "func": "const db = context.get(\"db\");\ntry{\n        const item = db.prepare(`\n        SELECT id, create_at, sent, energy_min, total_energy, energy_A, energy_B, co2 \n        FROM telemetry_energy_cloud\n        ORDER BY create_at DESC\n        LIMIT 10;\n        `).all();\n        msg.payload = item;\n        return msg;\n    } catch (err) {\n        node.error(err);\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\n// const Database = require('better-sqlite3');\ncontext.set(\"db\", new Database('/home/orangepi/telemetry/sql/telemetry_factory.db'));",
        "finalize": "// Code added here will be run when the\n// node is being stopped or re-deployed.\nconst db = context.get(\"db\");\nif (db) db.close();",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 360,
        "y": 420,
        "wires": [
            [
                "bc6e2d102e70107f"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "2d1b654aad918e8c",
        "type": "ui-table",
        "z": "cb99efbd3383440d",
        "group": "f9f9aa68ad730d89",
        "name": "Local Logging 10",
        "label": "Local Logging",
        "order": 2,
        "width": "6",
        "height": "0",
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": true,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 590,
        "y": 380,
        "wires": [
            []
        ]
    },
    {
        "id": "bc6e2d102e70107f",
        "type": "ui-table",
        "z": "cb99efbd3383440d",
        "group": "f9f9aa68ad730d89",
        "name": "Cloud Logging 10",
        "label": "Cloud Logging",
        "order": 1,
        "width": "6",
        "height": "0",
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": true,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 590,
        "y": 420,
        "wires": [
            []
        ]
    },
    {
        "id": "b3aef1aea38a6066",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "SELECT Local",
        "func": "const db = context.get(\"db\");\ntry{\n        const item = db.prepare(`\n        SELECT * \n        FROM telemetry_energy_logging\n        ORDER BY create_at DESC\n        LIMIT 100;\n        `).all();\n        msg.payload = item;\n        return msg;\n    } catch (err) {\n        node.error(err);\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\n// const Database = require('better-sqlite3');\ncontext.set(\"db\", new Database('/home/orangepi/telemetry/sql/telemetry_factory.db'));",
        "finalize": "// Code added here will be run when the\n// node is being stopped or re-deployed.\nconst db = context.get(\"db\");\nif (db) db.close();",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 360,
        "y": 520,
        "wires": [
            [
                "2a151e438bb6be7c"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "71670ab740b25226",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "SELECT Cloud",
        "func": "const db = context.get(\"db\");\ntry{\n        const item = db.prepare(`\n        SELECT * \n        FROM telemetry_energy_cloud\n        ORDER BY create_at DESC\n        LIMIT 100;\n        `).all();\n        msg.payload = item;\n        return msg;\n    } catch (err) {\n        node.error(err);\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\n// const Database = require('better-sqlite3');\ncontext.set(\"db\", new Database('/home/orangepi/telemetry/sql/telemetry_factory.db'));",
        "finalize": "// Code added here will be run when the\n// node is being stopped or re-deployed.\nconst db = context.get(\"db\");\nif (db) db.close();",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 360,
        "y": 560,
        "wires": [
            [
                "89377a52f086d706"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "2a151e438bb6be7c",
        "type": "ui-table",
        "z": "cb99efbd3383440d",
        "group": "e8820b5a1009efdc",
        "name": "Local Logging 100",
        "label": "Local Logging",
        "order": 1,
        "width": "0",
        "height": "0",
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": true,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 590,
        "y": 520,
        "wires": [
            []
        ]
    },
    {
        "id": "89377a52f086d706",
        "type": "ui-table",
        "z": "cb99efbd3383440d",
        "group": "eebb29937be17277",
        "name": "Cloud Logging 100",
        "label": "Cloud Logging",
        "order": 1,
        "width": "0",
        "height": "0",
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": true,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 590,
        "y": 560,
        "wires": [
            []
        ]
    },
    {
        "id": "3657f16d74d9481e",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "SELECT Meter",
        "func": "const db = context.get(\"db\");\ntry{\n        const item = db.prepare(`\n        SELECT * \n        FROM telemetry_energy\n        ORDER BY create_at DESC\n        LIMIT 100;\n        `).all();\n        msg.payload = item;\n        return msg;\n    } catch (err) {\n        node.error(err);\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\n// const Database = require('better-sqlite3');\ncontext.set(\"db\", new Database('/home/orangepi/telemetry/sql/telemetry_factory.db'));",
        "finalize": "// Code added here will be run when the\n// node is being stopped or re-deployed.\nconst db = context.get(\"db\");\nif (db) db.close();",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 360,
        "y": 600,
        "wires": [
            [
                "ae12c6bccb7e659e"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "ae12c6bccb7e659e",
        "type": "ui-table",
        "z": "cb99efbd3383440d",
        "group": "315e88c2f55060cc",
        "name": "Energy Logging  100",
        "label": "Energy Logging ",
        "order": 1,
        "width": "0",
        "height": "0",
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": true,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 600,
        "y": 600,
        "wires": [
            []
        ]
    },
    {
        "id": "bdb4b4beaeabc1e1",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "SELECT Cloud",
        "func": "const db = context.get(\"db\");\ntry{\n        const item = db.prepare(`\n        SELECT * \n        FROM telemetry_energy\n        ORDER BY create_at DESC\n        LIMIT 1;\n        `).all();\n        msg.payload = item;\n        return msg;\n    } catch (err) {\n        node.error(err);\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// Code added here will be run once\n// whenever the node is started.\n// const Database = require('better-sqlite3');\ncontext.set(\"db\", new Database('/home/orangepi/telemetry/sql/telemetry_factory.db'));",
        "finalize": "// Code added here will be run when the\n// node is being stopped or re-deployed.\nconst db = context.get(\"db\");\nif (db) db.close();",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 360,
        "y": 460,
        "wires": [
            [
                "970a34e5b50d3f93"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "970a34e5b50d3f93",
        "type": "ui-table",
        "z": "cb99efbd3383440d",
        "group": "f9f9aa68ad730d89",
        "name": "Local Energy Logging 10",
        "label": "Local Energy Logging",
        "order": 3,
        "width": "0",
        "height": "0",
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": false,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 610,
        "y": 460,
        "wires": [
            []
        ]
    },
    {
        "id": "a06ab2afde366b09",
        "type": "ui-event",
        "z": "cb99efbd3383440d",
        "ui": "d6f3a7fd07525d85",
        "name": "",
        "x": 170,
        "y": 100,
        "wires": [
            [
                "28bfd84cc4674302"
            ]
        ]
    },
    {
        "id": "4e1639b8fbf865ce",
        "type": "function",
        "z": "cb99efbd3383440d",
        "name": "function 30",
        "func": "msg.payload = {\n    \"fill\": \"red\",\n    \"shape\": \"dot\",\n    \"text\": `Time:${global.get(\"config.datetime.time\")}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 350,
        "y": 640,
        "wires": [
            []
        ]
    },
    {
        "id": "259aa3f685323a1f",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": true,
        "onceDelay": "3",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 135,
        "y": 140,
        "wires": [
            [
                "19ec6934475a43f6"
            ]
        ],
        "icon": "font-awesome/fa-clock-o",
        "l": false
    },
    {
        "id": "ebd6bc595f799807",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "10",
        "crontab": "",
        "once": true,
        "onceDelay": "3",
        "topic": "",
        "payload": "192.168.0.9",
        "payloadType": "str",
        "x": 135,
        "y": 60,
        "wires": [
            [
                "ebaa3baaf4745b67"
            ]
        ],
        "icon": "font-awesome/fa-globe",
        "l": false
    },
    {
        "id": "bffbd696e7e7a1d0",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 255,
        "y": 100,
        "wires": [
            [
                "5c386cb590032884"
            ]
        ],
        "l": false
    },
    {
        "id": "5c386cb590032884",
        "type": "exec",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "command": "reboot",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 315,
        "y": 100,
        "wires": [
            [],
            [],
            []
        ],
        "l": false
    },
    {
        "id": "137a2ed93b8bc4ba",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "10",
        "crontab": "",
        "once": true,
        "onceDelay": "3",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 405,
        "y": 60,
        "wires": [
            [
                "b77c666e9450adc3"
            ]
        ],
        "icon": "node-red/cog.svg",
        "l": false
    },
    {
        "id": "9b59d42b30816dd9",
        "type": "function",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "Data Management",
        "func": "const db = context.get(\"db\");\nif ((msg.topic != \"config\" && msg.topic != \"delete\") || !msg.topic) {\n    const eList = global.get(\"values.energyh\");\n    const hour = Number(global.get(\"config.datetime.hour\"));\n    const eStack = global.get(\"values.total.enstack\");\n    const ePrevious = context.get(\"previous\") || 0;\n    const baseLine = context.get(\"baseLine\");\n    const isRun = context.get(\"isRun\");\n    const ts = global.get(\"config.modbus.timestamp\") ?? 0;\n    const date_data = global.get(\"config.state.date_data\") ?? \"\";\n    const date_time = global.get(\"config.datetime.time\") ?? \"\";\n\n    const voltA = global.get(\"values.voltage.A\") ?? 0;\n    const voltB = global.get(\"values.voltage.B\") ?? 0;\n    const voltC = global.get(\"values.voltage.C\") ?? 0;\n\n    const currentA = global.get(\"values.current.A\") ?? 0;\n    const currentB = global.get(\"values.current.B\") ?? 0;\n    const currentC = global.get(\"values.current.C\") ?? 0;\n\n    const powerA = global.get(\"values.power.A\") ?? 0;\n    const powerB = global.get(\"values.power.B\") ?? 0;\n    const powerC = global.get(\"values.power.C\") ?? 0;\n\n    const pfA = global.get(\"values.powerfactor.A\") ?? 0;\n    const pfB = global.get(\"values.powerfactor.B\") ?? 0;\n    const pfC = global.get(\"values.powerfactor.C\") ?? 0;\n\n    const ppA = global.get(\"values.percentage.power.A\") ?? 0;\n    const ppB = global.get(\"values.percentage.power.B\") ?? 0;\n    const ppC = global.get(\"values.percentage.power.C\") ?? 0;\n\n    const pcA = global.get(\"values.percentage.current.A\") ?? 0;\n    const pcB = global.get(\"values.percentage.current.B\") ?? 0;\n    const pcC = global.get(\"values.percentage.current.C\") ?? 0;\n\n    const eTotal = context.get(\"eTotal\") ?? 0;\n    const eA = context.get(\"eA\") ?? 0;\n    const eB = context.get(\"eB\") ?? 0;\n    const co2 = context.get(\"co2\") ?? 0;\n    const eMinute = context.get(\"eMinutes\") ?? 0;\n    setBaselineNewday(hour);\n    async function setEn() {\n        return new Promise((resolve) => {\n                if ((isRun != hour) || (!context.get(\"nd\") && hour == 8)) { // ❗ทำงานเมื่เเปลี่ยนชั่วโมง และ เริ่มต้น\n                    setData(eList);\n                    eMinutes(eStack, ePrevious);\n                    context.set(\"nd\", true);\n                    let eNow = Math.trunc(parseFloat(eStack - baseLine) * 100) / 100;\n                    if (eNow) {\n                        if (hour == 8){\n                            node.warn('continue');\n                        } else if (hour == 0){\n                            let h = 23\n                            eList.splice(h, 1, eNow);\n                        }else{\n                            let h = hour - 1\n                            eList.splice(h, 1, eNow);\n                        }\n                    }\n                    if (eList[hour] > 0) {\n                        let baseLine = Math.trunc(parseFloat(eStack - eList[hour]) * 100) / 100;\n                        setBaseline(baseLine, hour);\n                    } else {\n                        setBaseline(eStack, hour);\n                    }\n                    // setBaseline(eStack, hour);\n                    node.status({ fill: \"yellow\", shape: \"dot\", text: `${global.get(\"config.datetime.time\")}` });\n                } else { // 🟢 ทำงานเมื่ออยู่ในชั่วโมง\n                    setData(eList);\n                    eMinutes(eStack, ePrevious);\n                    const eNow = Math.trunc(parseFloat(eStack - baseLine) * 100) / 100;\n                    if (eNow) {\n                        eList.splice(hour, 1, eNow);\n                    }\n                    node.status({ fill: \"green\", shape: \"dot\", text: `${global.get(\"config.datetime.time\")}` });\n                }\n                resolve('resolve');\n        })\n    };\n\n    const result = await setEn();\n    if(result){\n        try {\n            db.exec(`\n                BEGIN;\n                INSERT INTO telemetry_energy_logging(\n                    date_data, date_time, voltA, voltB, voltC,\n                    currentA, currentB, currentC,\n                    powerA, powerB, powerC,\n                    powerfA, powerfB, powerfC, \n                    powerpA, powerpB, powerpC,\n                    currentpA, currentpB, currentpC,\n                    total_e, energy_A, energy_B, co2\n                )\n                VALUES (\n                    '${date_data}', '${date_time}', \n                    ${voltA}, ${voltB}, ${voltC},\n                    ${currentA}, ${currentB}, ${currentC},\n                    ${powerA}, ${powerB}, ${powerC},\n                    ${pfA}, ${pfB}, ${pfC}, \n                    ${ppA}, ${ppB}, ${ppC},\n                    ${pcA}, ${pcB}, ${pcC},\n                    ${eTotal}, ${eA}, ${eB}, ${co2}\n                );\n\n                INSERT INTO telemetry_energy(\n                    e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19,e20,e21,e22,e23\n                )\n                VALUES (\n                    ${eList[0]}, ${eList[1]}, ${eList[2]}, ${eList[3]},\n                    ${eList[4]}, ${eList[5]}, ${eList[6]}, ${eList[7]},\n                    ${eList[8]}, ${eList[9]}, ${eList[10]}, ${eList[11]},\n                    ${eList[12]}, ${eList[13]}, ${eList[14]}, ${eList[15]},\n                    ${eList[16]}, ${eList[17]}, ${eList[18]}, ${eList[19]},\n                    ${eList[20]}, ${eList[21]}, ${eList[22]}, ${eList[23]}\n                );\n\n                INSERT INTO telemetry_energy_cloud(\n                    voltA, voltB, voltC,\n                    currentA, currentB, currentC,\n                    powerA, powerB, powerC,\n                    powerfA, powerfB, powerfC,\n                    energy, energy_min, energy_A, energy_B, total_energy, co2\n                )\n                VALUES (\n                    ${voltA}, ${voltB}, ${voltC},\n                    ${currentA}, ${currentB}, ${currentC},\n                    ${powerA}, ${powerB}, ${powerC},\n                    ${pfA}, ${pfB}, ${pfC},\n                    ${eList[hour]}, ${eMinute}, ${eA}, ${eB}, ${eTotal}, ${co2}\n                );\n                COMMIT;\n            `);\n            node.warn(`${global.get(\"config.datetime.time\")}: commit`);\n            node.status({ fill: \"blue\", shape: \"dot\", text: `INSERT INTO: ${global.get(\"config.datetime.time\")}` });\n            // return msg;\n        } catch (err) {\n            try {\n                db.exec(\"ROLLBACK;\");\n            } catch (e) { }\n            node.error(err);\n            node.status({ fill: \"blue\", shape: \"dot\", text: `ROLLBACK: ${global.get(\"config.datetime.time\")}` });\n            // return msg;\n        }\n    }else{\n        node.warn(`!result`);\n    }\n\n} else if (msg.topic == \"config\") {\n    let date = new Date(msg.timestamp);\n    let h = date.getHours();\n    node.warn(`${global.get(\"config.datetime.time\")}: config`);\n    node.status({ fill: \"yellow\", shape: \"dot\", text: `${global.get(\"config.datetime.time\")}` });\n    setConf(h, date);\n} else if (msg.topic == \"delete\") {\n    let date = new Date(msg.timestamp);\n    deleteSQL(date);\n    node.warn(`${global.get(\"config.datetime.time\")}: delete`);\n    node.status({ fill: \"red\", shape: \"dot\", text: `${global.get(\"config.datetime.time\")}` });\n}\nfunction setConf(h, timestamp) {\n    let startDate = new Date(timestamp);\n    let stopDate = new Date(timestamp);\n\n    if (h >= 8) {\n        // วันนี้ 08:00 → พรุ่งนี้ 08:00\n        stopDate.setDate(stopDate.getDate() + 1);\n    } else {\n        // เมื่อวาน 08:00 → วันนี้ 08:00\n        startDate.setDate(startDate.getDate() - 1);\n    }\n\n    let start = `${startDate.getFullYear()}-${(startDate.getMonth() + 1).toString().padStart(2, '0')}-${startDate.getDate().toString().padStart(2, '0')} 08:00:00`;\n\n    let stop = `${stopDate.getFullYear()}-${(stopDate.getMonth() + 1).toString().padStart(2, '0')}-${stopDate.getDate().toString().padStart(2, '0')} 08:00:00`;\n\n    try {\n        const item = db.prepare(`\n        SELECT * \n        FROM telemetry_energy_logging te\n        LEFT JOIN telemetry_energy tg \n        ON te.id = tg.id\n        WHERE te.create_at >= ?\n        AND te.create_at < ?\n        ORDER BY te.create_at DESC\n        LIMIT 1;\n        `).get(start, stop);\n        const payload = item;\n        const eArr = new Array(24).fill(0);\n        if (!item) {\n            global.set(\"values.energyh\", eArr)\n            node.status({ fill: \"red\", shape: \"dot\", text: \"config fail\" });\n        } else {\n            for (let i = 0; i < 24; i++) {\n                let objE = `e${i}`\n                eArr[i] = item[objE]\n            }\n            global.set(\"values.energyh\", eArr);\n            global.set(\"config.state.changehour\", getHourStamp(item.ts));\n            global.set(\"config.state.datestamp\", item.date_data);\n            node.status({ fill: \"green\", shape: \"dot\", text: `config successfuly` });\n        }\n        return payload\n    } catch (err) {\n        node.error(err);\n    }\n}\n\nfunction deleteSQL(date) {\n    let startDate = new Date(date);\n    startDate.setDate(startDate.getDate() - 7);\n    let start = `${startDate.getFullYear()}-${(startDate.getMonth() + 1).toString().padStart(2, '0')}-${startDate.getDate().toString().padStart(2, '0')} 08:00:00`;\n    // let start = '2026-07-09 09:43:33';\n    try {\n        db.prepare(`\n        DELETE FROM telemetry_energy_logging\n        WHERE create_at <= ?;\n        `).run(start);\n        db.prepare(`\n        DELETE FROM telemetry_energy\n        WHERE create_at <= ?;\n        `).run(start);\n        db.prepare(`\n        DELETE FROM telemetry_energy_cloud\n        WHERE create_at <= ?;\n        `).run(start);\n    } catch (err) {\n        node.error(err);\n    }\n}\nfunction getHourStamp(ts) {\n    let date = new Date(ts);\n    return Number(date.getHours().toString());\n}\n\nfunction eMinutes(now, prev) {\n    if (!prev){\n        context.set(\"eMinutes\", 0);\n        context.set(\"previous\", now);\n    }else{\n        const eMin = Math.trunc(parseFloat(now - prev) * 100) / 100;\n        context.set(\"eMinutes\", eMin);\n        context.set(\"previous\", now);\n    }\n}\n\nfunction setBaseline(e, h) {\n    context.set(\"baseLine\", e);\n    context.set(\"isRun\", h);\n}\n\nfunction setData(eList) {\n    const ts = global.get(\"config.datetime.timestamp\");\n    const date_data = global.get(\"config.state.date_data\");\n    const time_data = global.get(\"config.datetime.time\");\n    const posDay = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];\n    const posNigth = [20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7];\n    const eA = Math.trunc((posDay.reduce((acc, pos) => acc + (eList[pos]), 0)) * 1000) / 1000;\n    const eB = Math.trunc((posNigth.reduce((acc, pos) => acc + (eList[pos]), 0)) * 1000) / 1000;\n    const eTotal = eA + eB;\n    const co2 = Math.trunc(((eTotal * 5113) / 10000) * 100) / 100;\n    context.set(\"eTotal\", eTotal);\n    context.set(\"co2\", co2);\n    context.set(\"eA\", eA);\n    context.set(\"eB\", eB);\n    context.set(\"ts\", ts);\n    context.set(\"date_data\", date_data);\n    context.set(\"time_data\", time_data);\n}\n\nfunction setBaselineNewday(hour) {\n    if(hour == 7){\n        context.set(\"nd\", false);\n    }\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "// หน่วงเวลา 500ms รอให้ Node-RED โหลดโมดูล better-sqlite3 ให้เสร็จก่อน\nsetTimeout(() => {\n    try {\n        const dbPath = '/home/orangepi/telemetry/sql/telemetry_factory.db';\n        const db = new Database(dbPath);\n        context.set(\"db\", db);\n\n        // รันฟังก์ชันเซ็ตอัพหลังจากเชื่อมต่อฐานข้อมูลได้สำเร็จ\n        node.status({ fill: \"green\", shape: \"dot\", text: \"DB Connected\" });\n    } catch (err) {\n        node.error(\"SQLite Init Error: \" + err.message);\n        node.status({ fill: \"red\", shape: \"dot\", text: \"DB Connect Fail\" });\n    }\n}, 500);\n",
        "finalize": "try {\n    const db = context.get(\"db\");\n    // ตรวจสอบว่า db มีตัวตนจริงและมีฟังก์ชัน close หรือไม่ ก่อนจะสั่งปิด\n    if (db && typeof db.close === 'function') {\n        db.close();\n    }\n} catch (err) {\n    node.error(\"SQLite Close Error: \" + err.message);\n}\n",
        "libs": [
            {
                "var": "Database",
                "module": "better-sqlite3"
            }
        ],
        "x": 430,
        "y": 240,
        "wires": [
            [
                "d68b38d28bd387de"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "c347e1edd04abde6",
        "type": "subflow:cb99efbd3383440d",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "x": 160,
        "y": 300,
        "wires": []
    },
    {
        "id": "e0ae7c4a96d44ec1",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "config",
        "props": [
            {
                "p": "timestamp",
                "v": "",
                "vt": "date"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "",
        "crontab": "",
        "once": true,
        "onceDelay": "1",
        "topic": "config",
        "x": 315,
        "y": 260,
        "wires": [
            [
                "9b59d42b30816dd9"
            ]
        ],
        "icon": "font-awesome/fa-repeat",
        "l": false
    },
    {
        "id": "d68b38d28bd387de",
        "type": "subflow:84cf72481f1ee5df",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "x": 610,
        "y": 240,
        "wires": []
    },
    {
        "id": "7055b8fea6b969b0",
        "type": "subflow:be61994cf1b15e59",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "env": [
            {
                "name": "UnitID",
                "value": "2",
                "type": "num"
            },
            {
                "name": "Unit ID:",
                "value": "3",
                "type": "num"
            }
        ],
        "x": 160,
        "y": 240,
        "wires": [
            [
                "11d4094ef1e35e1e"
            ]
        ]
    },
    {
        "id": "11d4094ef1e35e1e",
        "type": "delay",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "pauseType": "rate",
        "timeout": "5",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "minute",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 265,
        "y": 240,
        "wires": [
            [
                "9b59d42b30816dd9"
            ]
        ],
        "l": false
    },
    {
        "id": "811b106f17562478",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "5",
        "crontab": "",
        "once": true,
        "onceDelay": "30",
        "topic": "",
        "payload": "python3 telemetry/py/telemetry_streaming_local.py ",
        "payloadType": "str",
        "x": 715,
        "y": 240,
        "wires": [
            [
                "7d3113f0d1f6fdd4"
            ]
        ],
        "icon": "node-red/arrow-in.svg",
        "l": false
    },
    {
        "id": "7d3113f0d1f6fdd4",
        "type": "exec",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "command": "",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "py",
        "x": 765,
        "y": 260,
        "wires": [
            [
                "1535ea695344fdc5"
            ],
            [],
            []
        ],
        "l": false
    },
    {
        "id": "172b16477f714016",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "5",
        "crontab": "",
        "once": true,
        "onceDelay": "32",
        "topic": "",
        "payload": "python3 /home/orangepi/telemetry/py/telemetry_streaming_cloud.py",
        "payloadType": "str",
        "x": 715,
        "y": 280,
        "wires": [
            [
                "7d3113f0d1f6fdd4"
            ]
        ],
        "l": false
    },
    {
        "id": "c5fb9ad7e2c125ef",
        "type": "subflow:e226ede58ea4b202",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "",
        "x": 420,
        "y": 300,
        "wires": []
    },
    {
        "id": "19ec6934475a43f6",
        "type": "subflow:a67f25631bef1988",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "x": 230,
        "y": 140,
        "wires": []
    },
    {
        "id": "42d38ab61e124a52",
        "type": "subflow:31057fe0b0d4c1ec",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "x": 315,
        "y": 60,
        "wires": [],
        "l": false
    },
    {
        "id": "ebaa3baaf4745b67",
        "type": "subflow:13f006802899e0be",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "x": 230,
        "y": 60,
        "wires": [
            [
                "42d38ab61e124a52"
            ]
        ]
    },
    {
        "id": "b77c666e9450adc3",
        "type": "subflow:df4a94479416f0c4",
        "z": "e17edba087392acf",
        "g": "4a03533f0307f7ce",
        "name": "",
        "x": 490,
        "y": 60,
        "wires": []
    },
    {
        "id": "7dc780c084014273",
        "type": "inject",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "delete",
        "props": [
            {
                "p": "timestamp",
                "v": "",
                "vt": "date"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "",
        "crontab": "",
        "once": true,
        "onceDelay": "5",
        "topic": "delete",
        "x": 265,
        "y": 300,
        "wires": [
            [
                "9b59d42b30816dd9"
            ]
        ],
        "icon": "node-red/alert.svg",
        "l": false
    },
    {
        "id": "1535ea695344fdc5",
        "type": "debug",
        "z": "e17edba087392acf",
        "g": "46bfaf6a02f976b1",
        "name": "debug 1",
        "active": false,
        "tosidebar": true,
        "console": false,
        "tostatus": false,
        "complete": "true",
        "targetType": "full",
        "statusVal": "",
        "statusType": "auto",
        "x": 815,
        "y": 240,
        "wires": [],
        "icon": "node-red/comment.svg",
        "l": false
    }
]
EON

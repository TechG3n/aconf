# Webhook receiver for getting data from ATV devices
# replacement for ATVdetails
#
__author__ = "GhostTalker and Apple314"
__copyright__ = "Copyright 2022, The GhostTalker project"
__version__ = "0.1.2"
__status__ = "DEV"

import os
import sys
import time
import datetime
import json
import requests
import configparser
import pymysql
from mysql.connector import Error
from mysql.connector import pooling
from flask import Flask, request

## read config
_config = configparser.ConfigParser()
_rootdir = os.path.dirname(os.path.abspath('config.ini'))
_config.read(_rootdir + "/config.ini")
_host = _config.get("socketserver", "host", fallback='0.0.0.0')
_port = _config.get("socketserver", "port", fallback='5050')
_mysqlhost = _config.get("mysql", "mysqlhost", fallback='127.0.0.1')
_mysqlport = _config.get("mysql", "mysqlport", fallback='3306')
_mysqldb = _config.get("mysql", "mysqldb")
_mysqluser = _config.get("mysql", "mysqluser")
_mysqlpass = _config.get("mysql", "mysqlpass")

## do validation and checks before insert
def validate_string(val):
   if val != None:
        if type(val) is int:
            #for x in val:
            #   print(x)
            return str(val).encode('utf-8')
        else:
            return val

## create connection pool and connect to MySQL
try:
    connection_pool = pooling.MySQLConnectionPool(pool_name="mysql_connection_pool",
                                                  pool_size=5,
                                                  pool_reset_session=True,
                                                  host=_mysqlhost,
                                                  port=_mysqlport,
                                                  database=_mysqldb,
                                                  user=_mysqluser,
                                                  password=_mysqlpass)

    print("Create connection pool: ")
    print("Connection Pool Name - ", connection_pool.pool_name)
    print("Connection Pool Size - ", connection_pool.pool_size)

    # Get connection object from a pool
    connection_object = connection_pool.get_connection()

    if connection_object.is_connected():
        db_Info = connection_object.get_server_info()
        print("Connected to MySQL database using connection pool ... MySQL Server version on ", db_Info)

        cursor = connection_object.cursor()
        cursor.execute("select database();")
        record = cursor.fetchone()
        print("You're connected to - ", record)

except Error as e:
    print("Error while connecting to MySQL using Connection pool ", e)

finally:
    # closing database connection.
    if connection_object.is_connected():
        cursor.close()
        connection_object.close()
        print("MySQL connection is closed")

## webhook receiver
app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    if request.method == 'POST':
        print("Data received from Webhook is: ", request.json)

        # parse json data to SQL insert
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        deviceName = validate_string(request.json["deviceName"])
        arch = validate_string(request.json["arch"])
        productmodel = validate_string(request.json["productmodel"])
        atlasSh = validate_string(request.json["atlasSh"])
        atlas55 = validate_string(request.json["atlas55"])
        monitor = validate_string(request.json["monitor"])
        pogo = validate_string(request.json["pogo"])
        atlas = validate_string(request.json["atlas"])
        temperature = validate_string(request.json["temperature"])
        magisk = validate_string(request.json["magisk"])
        magisk_modules = validate_string(request.json["magisk_modules"])
        macw = validate_string(request.json["macw"])
        mace = validate_string(request.json["mace"])
        ip = validate_string(request.json["ip"])
        ext_ip = validate_string(request.json["ext_ip"])
        hostname = validate_string(request.json["hostname"])
        diskSysPct = validate_string(request.json["diskSysPct"])
        diskDataPct = validate_string(request.json["diskDataPct"])
        RPL = validate_string(request.json["RPL"])
        memTot = validate_string(request.json["memTot"])
        memFree = validate_string(request.json["memFree"])
        memAv = validate_string(request.json["memAv"])
        memPogo = validate_string(request.json["memPogo"])
        memAtlas = validate_string(request.json["memAtlas"])
        cpuSys = validate_string(request.json["cpuSys"])
        cpuUser = validate_string(request.json["cpuUser"])
        cpuL5 = validate_string(request.json["cpuL5"])
        cpuL10 = validate_string(request.json["cpuL10"])
        cpuL15 = validate_string(request.json["cpuL15"])
        cpuPogoPct = validate_string(request.json["cpuPogoPct"])
        cpuApct = validate_string(request.json["cpuApct"]) 
        numPogo = validate_string(request.json["numPogo"])
        reboot = validate_string(request.json["reboot"])
        whversion = validate_string(request.json["whversion"])

        insert_stmt1 = "\
            INSERT INTO ATVsummary \
                (timestamp, \
                deviceName, \
                arch, \
                productmodel, \
                atlasSh, \
                55atlas, \
                monitor, \
                pogo, \
                atlas, \
                temperature, \
                magisk, \
                magisk_modules, \
                MACw, \
                MACe, \
                ip, \
                ext_ip, \
                hostname, \
                diskSysPct, \
                diskDataPct, \
                whversion, \
                numPogo, \
                reboot) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) \
            ON DUPLICATE KEY UPDATE \
                timestamp = VALUES(timestamp), \
                deviceName = VALUES(deviceName), \
                arch = VALUES(arch), \
                productmodel = VALUES(productmodel), \
                atlasSh = VALUES(atlasSh), \
                55atlas = VALUES(55atlas), \
                pogo = VALUES(pogo), \
                atlas = VALUES(atlas), \
                monitor = VALUES(monitor), \
                temperature = VALUES(temperature), \
                magisk = VALUES(magisk), \
                magisk_modules = VALUES(magisk_modules), \
                MACw = VALUES(MACw), \
                MACe = VALUES(MACe), \
                ip = VALUES(ip), \
                ext_ip = VALUES(ext_ip), \
                hostname = VALUES(hostname), \
                diskSysPct = VALUES(diskSysPct), \
                diskDataPct = VALUES(diskDataPct), \
                whversion = VALUES(whversion), \
                numPogo = VALUES(numPogo), \
                reboot = VALUES(reboot)"

        data1 = (str(timestamp), str(deviceName), str(arch), str(productmodel), str(atlasSh), str(atlas55), str(pogo), str(atlas), str(monitor), str(temperature), str(magisk), str(magisk_modules), str(macw), str(mace), str(ip), str(ext_ip), str(hostname), str(diskSysPct), str(diskDataPct), str(whversion), str(numPogo) )

        insert_stmt2 = (
            "INSERT INTO ATVstats (timestamp, RPL, deviceName, temperature, memTot, memFree, memAv, memPogo, memAtlas, cpuSys, cpuUser, cpuL5, cpuL10, cpuL15, cpuPogoPct, cpuApct, diskSysPct, diskDataPct)"
            "VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )"
        )        
        
        data2 = (str(timestamp), str(RPL), str(deviceName), str(temperature), str(memTot), str(memFree), str(memAv), str(memPogo), str(memAtlas), str(cpuSys), str(cpuUser), str(cpuL5), str(cpuL10), str(cpuL15), str(cpuPogoPct), str(cpuApct), str(diskSysPct), str(diskDataPct) )

        try:
            connection_object = connection_pool.get_connection()
        
            # Get connection object from a pool
            if connection_object.is_connected():
                print("MySQL pool connection is open.")
                # Executing the SQL command
                cursor = connection_object.cursor()
                cursor.execute(insert_stmt1, data1)
                cursor.execute(insert_stmt2, data2)
                connection_object.commit()
                print("Data inserted")
                
        except Exception as e:
            # Rolling back in case of error
            connection_object.rollback()
            print(e)
            print("Data NOT inserted. rollbacked.")

        finally:
            # closing database connection.
            if connection_object.is_connected():
                cursor.close()
                connection_object.close()
                print("MySQL pool connection is closed.")

        return "Webhook received!"

# start scheduling
try:
    app.run(host=_host, port=_port)
	
except KeyboardInterrupt:
    print("Webhook receiver will be stopped")
    exit(0)

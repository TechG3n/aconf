# Webhook receiver for getting data from ATV devices
# replacement for ATVdetails
#
__author__ = "GhostTalker and Apple314"
__copyright__ = "Copyright 2022, The GhostTalker project"
__version__ = "0.3.2"
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
    # check if val None oder empty is
    if val is None or val == '' or val == []:
        return 0
    elif isinstance(val, int):
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

    if request.method == 'POST' and request.json["WHType"] == 'ATVMonitor':
        print("Data received from ATV Monitor Webhook is: ", request.json)

        # parse json data to SQL insert
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        deviceName = validate_string(request.json["deviceName"])
        issue = validate_string(request.json["issue"])
        action = validate_string(request.json["action"])
        script = validate_string(request.json["script"])

        insert_stmt_monitor = (
            "INSERT INTO ATVMonitor (timestamp, deviceName, issue, action, script)"
            "VALUES ( %s, %s, %s, %s, %s )"
        )

        data_monitor = ( str(timestamp), str(deviceName), str(issue), str(action), str(script) )

        try:
            connection_object = connection_pool.get_connection()

            # Get connection object from a pool
            if connection_object.is_connected():
                print("MySQL pool connection is open.")
                # Executing the SQL command
                cursor = connection_object.cursor()
                cursor.execute(insert_stmt_monitor, data_monitor)
                connection_object.commit()
                print("Monitor Data inserted")

        except Exception as e:
            # Rolling back in case of error
            connection_object.rollback()
            print(e)
            print("Monitor Data NOT inserted. rollbacked.")

        finally:
            # closing database connection.
            if connection_object.is_connected():
                cursor.close()
                connection_object.close()
                print("MySQL pool connection is closed.")

        return "Monitor Webhook received!"


    if request.method == 'POST' and request.json["WHType"] == 'ATVDetails':
        print("Data received from ATV Details Webhook is: ", request.json)

        # parse json data to SQL insert
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        deviceName = validate_string(request.json["deviceName"])
        arch = validate_string(request.json["arch"])
        productmodel = validate_string(request.json["productmodel"])
        MITMSh = validate_string(request.json["MITMSh"])
        MITM55 = validate_string(request.json["MITM55"])
        MITM42 = validate_string(request.json["MITM42"])
        monitor = validate_string(request.json["monitor"])
        pogo = validate_string(request.json["pogo"])
        MITMv = validate_string(request.json["MITMv"])
        temperature = validate_string(request.json["temperature"])
        magisk = validate_string(request.json["magisk"])
        magisk_modules = validate_string(request.json["magisk_modules"])
        macw = validate_string(request.json["macw"])
        mace = validate_string(request.json["mace"])
        ip = validate_string(request.json["ip"])
        ext_ip = validate_string(request.json["ext_ip"])
        hostname = validate_string(request.json["hostname"])
        playstore = validate_string(request.json["playstore"])
        proxyinfo = validate_string(request.json["proxyinfo"])
        diskSysPct = validate_string(request.json["diskSysPct"])
        diskDataPct = validate_string(request.json["diskDataPct"])
        RPL = validate_string(request.json["RPL"])
        MITM = validate_string(request.json["MITM"])
        memTot = validate_string(request.json["memTot"])
        memFree = validate_string(request.json["memFree"])
        memAv = validate_string(request.json["memAv"])
        memPogo = validate_string(request.json["memPogo"])
        memMITM = validate_string(request.json["memMITM"])
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
        authBearer = validate_string(request.json["authBearer"])
        token = validate_string(request.json["token"])
        email = validate_string(request.json["email"])
        rdmUrl = validate_string(request.json["rdmUrl"])
        onBoot = validate_string(request.json["onBoot"])
        a_pogoStarted = validate_string(request.json["a_pogoStarted"])
        a_injection = validate_string(request.json["a_injection"])
        a_ptcLogin = validate_string(request.json["a_ptcLogin"])
        a_MITMCrash = validate_string(request.json["a_MITMCrash"])
        a_rdmError = validate_string(request.json["a_rdmError"])
        m_noInternet = validate_string(request.json["m_noInternet"])
        m_noConfig = validate_string(request.json["m_noConfig"])
        m_noLicense = validate_string(request.json["m_noLicense"])
        m_MITMDied = validate_string(request.json["m_MITMDied"])
        m_pogoDied = validate_string(request.json["m_pogoDied"])
        m_deviceOffline = validate_string(request.json["m_deviceOffline"])
        m_noRDM = validate_string(request.json["m_noRDM"])
        m_noFocus = validate_string(request.json["m_noFocus"])
        m_unknown = validate_string(request.json["m_unknown"])

        insert_stmt1 = "\
            INSERT INTO ATVsummary \
                (timestamp, \
                MITM, \
                deviceName, \
                arch, \
                productmodel, \
                MITMSh, \
                55MITM, \
                42MITM, \
                monitor, \
                pogo, \
                MITM, \
                temperature, \
                magisk, \
                magisk_modules, \
                MACw, \
                MACe, \
                ip, \
                ext_ip, \
                hostname, \
                playstore, \
                proxyinfo, \
                diskSysPct, \
                diskDataPct, \
                whversion, \
                numPogo, \
                reboot, \
                authBearer, \
                token, \
                email, \
                rdmUrl, \
                onBoot) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) \
            ON DUPLICATE KEY UPDATE \
                timestamp = VALUES(timestamp), \
                MITM = VALUES(MITM), \
                deviceName = VALUES(deviceName), \
                arch = VALUES(arch), \
                productmodel = VALUES(productmodel), \
                MITMSh = VALUES(MITMSh), \
                55MITM = VALUES(55MITM), \
                42MITM = VALUES(42MITM), \
                monitor = VALUES(monitor), \
                pogo = VALUES(pogo), \
                MITM = VALUES(MITMv), \
                temperature = VALUES(temperature), \
                magisk = VALUES(magisk), \
                magisk_modules = VALUES(magisk_modules), \
                MACw = VALUES(MACw), \
                MACe = VALUES(MACe), \
                ip = VALUES(ip), \
                ext_ip = VALUES(ext_ip), \
                hostname = VALUES(hostname), \
                playstore = VALUES(playstore), \
                proxyinfo = VALUES(proxyinfo), \
                diskSysPct = VALUES(diskSysPct), \
                diskDataPct = VALUES(diskDataPct), \
                whversion = VALUES(whversion), \
                numPogo = VALUES(numPogo), \
                reboot = VALUES(reboot), \
                authBearer = VALUES(authBearer), \
                token = VALUES(token), \
                email = VALUES(email), \
                rdmUrl = VALUES(rdmUrl), \
                onBoot = VALUES(onBoot)"

        data1 = (str(timestamp), str(MITM), str(deviceName), str(arch), str(productmodel), str(MITMSh), str(MITM55), str(MITM42), str(monitor), str(pogo), str(MITMv), str(temperature), str(magisk), str(magisk_modules), str(macw), str(mace), str(ip), str(ext_ip), str(hostname), str(playstore), str(proxyinfo), str(diskSysPct), str(diskDataPct), str(whversion), str(numPogo), str(reboot), str(authBearer), str(token), str(email), str(rdmUrl), str(onBoot) )

        insert_stmt2 = (
            "INSERT INTO ATVstats (timestamp, RPL, deviceName, temperature, memTot, memFree, memAv, memPogo, mematlas, cpuSys, cpuUser, cpuL5, cpuL10, cpuL15, cpuPogoPct, cpuApct, diskSysPct, diskDataPct)"
            "VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )"
        )

        data2 = (str(timestamp), str(RPL), str(deviceName), str(temperature), str(memTot), str(memFree), str(memAv), str(memPogo), str(memMITM), str(cpuSys), str(cpuUser), str(cpuL5), str(cpuL10), str(cpuL15), str(cpuPogoPct), str(cpuApct), str(diskSysPct), str(diskDataPct) )

        insert_stmt3 = "\
            INSERT INTO ATVlogs \
                (timestamp, \
                deviceName, \
                reboot, \
                a_pogoStarted, \
                a_injection, \
                a_ptcLogin, \
                a_atlasCrash, \
                a_rdmError, \
                m_noInternet, \
                m_noConfig, \
                m_noLicense, \
                m_atlasDied, \
                m_pogoDied, \
                m_deviceOffline, \
                m_noRDM, \
                m_noFocus, \
                m_unknown) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) \
            ON DUPLICATE KEY UPDATE \
                timestamp = VALUES(timestamp), \
                deviceName = VALUES(deviceName), \
                reboot = VALUES(reboot), \
                a_pogoStarted = VALUES(a_pogoStarted), \
                a_injection = VALUES(a_injection), \
                a_ptcLogin = VALUES(a_ptcLogin), \
                a_atlasCrash = VALUES(a_MITMCrash), \
                a_rdmError = VALUES(a_rdmError), \
                m_noInternet = VALUES(m_noInternet), \
                m_noConfig = VALUES(m_noConfig), \
                m_noLicense = VALUES(m_noLicense), \
                m_atlasDied = VALUES(m_MITMDied), \
                m_pogoDied = VALUES(m_pogoDied), \
                m_deviceOffline = VALUES(m_deviceOffline), \
                m_noRDM = VALUES(m_noRDM), \
                m_noFocus = VALUES(m_noFocus), \
                m_unknown = VALUES(m_unknown)"

        data3 = (str(timestamp), str(deviceName), str(reboot), str(a_pogoStarted), str(a_injection), str(a_ptcLogin), str(a_MITMCrash), str(a_rdmError), str(m_noInternet), str(m_noConfig), str(m_noLicense), str(m_MITMDied), str(m_pogoDied), str(m_deviceOffline), str(m_noRDM), str(m_noFocus), str(m_unknown) )

        try:
            connection_object = connection_pool.get_connection()

            # Get connection object from a pool
            if connection_object.is_connected():
                print("MySQL pool connection is open.")
                # Executing the SQL command
                cursor = connection_object.cursor()
                cursor.execute(insert_stmt1, data1)
                cursor.execute(insert_stmt2, data2)
                cursor.execute(insert_stmt3, data3)
                connection_object.commit()
                print("ATVDetails Data inserted")

        except Exception as e:
            # Rolling back in case of error
            connection_object.rollback()
            print(e)
            print("ATVDetails Data NOT inserted. rollbacked.")

        finally:
            # closing database connection.
            if connection_object.is_connected():
                cursor.close()
                connection_object.close()
                print("MySQL pool connection is closed.")

        return "ATVDetails Webhook received!"

# start scheduling
try:
    app.run(host=_host, port=_port)

except KeyboardInterrupt:
    print("Webhook receiver will be stopped")
    exit(0)

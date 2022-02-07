#!/usr/bin/env python

import json
import os
import requests

homeDir = os.path.expanduser("~")
configFile = os.path.join(homeDir, ".vault-config.json")
vaultAddr = os.environ['VAULT_ADDR']

URL_VAULT_INIT = "%s/v1/sys/init" % vaultAddr
URL_VAULT_SEAL_STATUS = "%s/v1/sys/seal-status" % vaultAddr
URL_VAULT_UNSEAL = "%s/v1/sys/unseal" % vaultAddr

def vaultIsInitialized():
  try:
    r = requests.get(URL_VAULT_INIT)
    checkHttpStatus(r)
    return r.json()['initialized']
  except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
    print "ERR: Error connecting to Vault server"
    exit()

def vaultInitialize(shares=1, threshold=1):
  payload = '{"secret_shares" : %d, "secret_threshold" : %d}' % (shares, threshold)
  try:
    r = requests.put(URL_VAULT_INIT, data=payload)
    checkHttpStatus(r)
    saveVaultConfiguration(r.text)
    return r.json()
  except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
    print "ERR: Error connecting to Vault server"
    exit()

def vaultGetSealStatus():
  try:
    r = requests.get(URL_VAULT_SEAL_STATUS)
    checkHttpStatus(r)
    return r.json()
  except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
    print "ERR: Error connecting to Vault server"
    exit()

def vaultIsSealed():
  return vaultGetSealStatus()['sealed']

def vaultUnseal():
  if not configFileExists():
    print "ERR: Vault config file not found"
    exit()

  config = loadVaultConfiguration()
  keys = config['keys']

  status = vaultGetSealStatus()
  if not status['sealed']:
    return status

  threshold = status['t']
  progress = status['progress']

  for i in range(progress, threshold):
    payload = '{"key" : "%s"}' % (keys[i])
    try:
      r = requests.put(URL_VAULT_UNSEAL, data=payload)
      checkHttpStatus(r)
    except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
      print "ERR: Error connecting to Vault server"
      exit()

  return vaultIsSealed()

def configFileExists():
  return os.path.exists(configFile)

def loadVaultConfiguration():
  with open(configFile, "r") as data:
    return json.load(data)

def saveVaultConfiguration(content):
  file = open(configFile, "w")
  file.write(content)
  file.close()

def checkHttpStatus(req, status=requests.codes.ok):
  if not req.status_code == status:
    print("ERR: Unexpected response status")
    exit()

### MAIN ###
print "Configuring Vault..."

if not vaultIsInitialized():
  print "Vault is not initialized. Initializing..."
  vaultInitialize();
else:
  print "Vault is already initialized."

if vaultIsSealed():
  print "Vault is sealed. Unsealing..."
  if vaultUnseal():
    print "Vault is still sealed"
  else:
    print "Vault is now unsealed"
else:
  print "Vault is already unsealed. Nothing to do here!"

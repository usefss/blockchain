import json
import os

config_data = json.load(open(os.path.join('agents', 'config.json')))


BLOCKCHAIN_ADDRESS = config_data['networks']['develop']['host'] + \
                    ':' + config_data['networks']['develop']['port']
import json

from flask import Flask, render_template

from web3.auto import w3
from solc import compile_source
import time
from datetime import datetime
from datetime import timedelta

app = Flask(__name__)

contract_source_code = None
contract_source_code_file = 'CoinFund.sol'

with open(contract_source_code_file, 'r') as file:
    contract_source_code = file.read()

w3.eth.defaultAccount = w3.eth.accounts[0]

contract_compiled = compile_source(contract_source_code, allow_paths=".")
contract_interface = contract_compiled['<stdin>:Campaign']
campaign = w3.eth.contract(abi=contract_interface['abi'], 
                          bytecode=contract_interface['bin'])

name = "Edric"
email = "edric@gmail.com"
title = "Coin Fund"
description = "Blockchain-based Crowdfunding Campaign"
target = w3.toWei(10, 'ether')
monthly = w3.toWei(4, 'ether')
start = datetime.now()
end = start + timedelta(minutes=1)

start = int(datetime.timestamp(start))
end = int(datetime.timestamp(end))

tx_hash = campaign.constructor(name, email, title, description, target, monthly, start, end).transact({'from':w3.eth.accounts[0]})
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

Campaign = w3.eth.contract(address=tx_receipt.contractAddress, abi=contract_interface['abi'])

# Web service initialization
@app.route('/')
@app.route('/index')
def hello():
    return render_template('template.html', contractAddress = Campaign.address.lower(), contractABI = json.dumps(contract_interface['abi']))

if __name__ == '__main__':
    app.debug = True
    app.run(port=5001)


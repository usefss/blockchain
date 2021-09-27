from web3 import Web3
from eth_account import Account

from . import config

class BaseAgent:
    account: Account = None
    web3: Web3 = None

    def __init__(self, *args, **kwargs):
        self.set_agent_wallet()
        self.set_web3_object()

        self.setUp(*args, **kwargs)

    def setUp(self, *args, **kwargs):
        raise NotImplemented

    def set_web3_object(self, ):
        self.web3 = Web3(Web3.HTTPProvider(config.BLOCKCHAIN_ADDRESS))

    def set_agent_wallet(self, ):
        """
            this creates a totally random account
            get self.account.key.hex()
        """
        self.account = Account.create()
    
    @property
    def balance(self, ):
        return self.web3.eth.get_balance(
            self.account.address
        )
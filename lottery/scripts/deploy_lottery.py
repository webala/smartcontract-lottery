from .helpful_scripts import get_account, get_contract
from brownie import Lottery, network


def deploy_lottery():
    account = get_account()
    lottery = Lottery.deploy(
        get_contract('eth_usd_price_feed').address,
        2506,
        {'from': account},
    )
    print('Deployed lottery')
    print(lottery.address)

def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    lottery.startLottery({'from': account})
    print('The lottery has started')

def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    value = lottery.getEntranceFee() + 100000000
    tx = lottery.enter({'from': account, 'value': value})
    tx.wait(1)
    print("You entered the lottery!") 

def end_lottery():
    account = get_account()
    lottery = Lottery[-1]
    lottery.endLottery({'from': account})

def main():
    end_lottery()
    
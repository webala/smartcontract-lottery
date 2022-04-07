# 0..014417532
from brownie import Lottery, accounts, config, network
from web3 import Web3


def test_get_entrance_fee():
    account = accounts[0]
    print(account)
    lottery = Lottery.deploy(
        config["networks"][network.show_active()]["eth_usd_price_feed"],
        {"from": account},
    )

    assert lottery.getEntranceFee() > Web3.toWei(0.013, 'ether')
    assert lottery.getEntranceFee() < Web3.toWei(0.015, 'ether')
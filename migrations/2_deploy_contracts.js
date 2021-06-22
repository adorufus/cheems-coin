const CheemsToken = artifacts.require('CheemsToken')
const DaiToken = artifacts.require('DaiToken')
const TokenFarm = artifacts.require("TokenFarm");

module.exports = async function(deployer, network, accounts) {
    //deploy DaiToken
    await deployer.deploy(DaiToken)
    const daiToken = await DaiToken.deployed()

    //deploy cheemstoken
    await deployer.deploy(CheemsToken)
    const cheemsToken = await CheemsToken.deployed()

    //deploy TokenFarm
    await deployer.deploy(TokenFarm, cheemsToken.address, daiToken.address);
    const tokenFarm = await TokenFarm.deployed()

    //transfer all tokens to TokenFarm (1mil)
    await cheemsToken.transfer(tokenFarm.address, '1000000000000000000000000')

    await daiToken.transfer(accounts[1], '100000000000000000000')
};

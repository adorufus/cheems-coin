const { assert } = require('chai');

const DappToken = artifacts.require('DappToken')
const DaiToken = artifacts.require('DaiToken')
const TokenFarm = artifacts.require("TokenFarm");

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('TokenFarm', ([owner, investor]) => {
    let daiToken, dappToken, tokenFarm

    function tokens(n) {
        return web3.utils.toWei(n, 'Ether')
    }

    before(async () => {
        daiToken = await DaiToken.new()
        dappToken = await DappToken.new()
        tokenFarm = await TokenFarm.new(dappToken.address, daiToken.address)

        await dappToken.transfer(tokenFarm.address, tokens('1000000'))
        await daiToken.transfer(investor, tokens('100'), {from: owner})
    })

    describe('Mock DAI Deployment', async () => {
        it('has a name', async () => {
            const name = await daiToken.name()
            assert.equal(name, 'Mock DAI Token')
        })
    })

    describe('Cheems Deployment', async () => {
        it('has a name', async () => {
            const name = await dappToken.name()
            assert.equal(name, 'Cheems')
        })
    })

    describe('TokenFarm Deployment', async () => {
        it('has a name', async () => {
            const name = await tokenFarm.name()
            assert.equal(name, 'Cheems Token Farm')
        })

        it('contract has tokens', async () => {
            let balance = await dappToken.balanceOf(tokenFarm.address)
            assert.equal(balance.toString(), tokens('1000000'))
        })
    })

    describe('Farming tokens', async () => {
        it('rewards investor for staking mDai tokens', async () => {
            let result
            
            //check investor balance before staking
            result = await daiToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('100'), 'investor mDai balance correct before staking')

            //stake mDai tokens to TokenFarm
            await daiToken.approve(tokenFarm.address, tokens('100'), {from: investor})
            await tokenFarm.stakeToken(tokens('100'), {from: investor})

            //check staking result
            result = await daiToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('0'), 'investor mDai wallet balance correct before staking')

            result = await daiToken.balanceOf(tokenFarm.address)
            assert.equal(result.toString(), tokens('100'), 'TokenFarm balance correct after staking')

            result = await tokenFarm.stakingBalance(investor)
            assert.equal(result.toString(), tokens('100'), 'investor staking balance correct after staking')

            result = await tokenFarm.isStaking(investor)
            assert.equal(result.toString(), 'true', 'investor staking status correct after staking')

            //issue token
            await tokenFarm.issueToken({from: owner})

            //check balance after issuance
            result = await dappToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('100'), 'investor Cheems Token wallet balance correct after staking')

            //Ensure that only owner can issue tokens
            await tokenFarm.issueToken({from: investor}).should.be.rejected;
            
            await tokenFarm.unstakeToken({from: investor})

            result = await daiToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('100'), 'investor mDai wallet balance correct after unstaking')

            result = await daiToken.balanceOf(tokenFarm.address)
            assert.equal(result.toString(), tokens('0'), 'TokenFarm balance correct after staking')

            result = await tokenFarm.stakingBalance(investor)
            assert.equal(result.toString(), tokens('0'), 'investor staking balance correct after staking')

            result = await tokenFarm.isStaking(investor)
            assert.equal(result.toString(), 'false', 'investor staking status correct after staking')
        })
    })
})
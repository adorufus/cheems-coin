import React, { Component } from 'react'
import Web3 from 'web3'
import DaiToken from '../abis/DaiToken.json'
import CheemsToken from '../abis/DappToken.json'
import TokenFarm from '../abis/TokenFarm.json'
import Navbar from './Navbar'
import Main from './Main'
import './App.css'

class App extends Component {

  async componentDidMount() {
    await this.loadWeb3();
    await this.loadBlockChainData();
  }

  async loadBlockChainData() {
    const web3 = window.web3

    const accounts = await web3.eth.getAccounts()

    this.setState({account: accounts[0]})

    const networkId = await web3.eth.net.getId()

    //DaiToken init
    const daiTokenData = DaiToken.networks[networkId]
    if(daiTokenData) {
      const daiToken = new web3.eth.Contract(DaiToken.abi, daiTokenData.address)
      this.setState({daiToken})
      let daiTokenBalance = await daiToken.methods.balanceOf(this.state.account).call()
      this.setState({daiTokenBalance: daiTokenBalance.toString()})
    } else {
      window.alert('DaiToken Contract not deployed to detected network.')
    }

    //cheems token init
    const cheemsTokenData = CheemsToken.networks[networkId]
    if(cheemsTokenData) {
      const cheemsToken = new web3.eth.Contract(CheemsToken.abi, cheemsTokenData.address)
      this.setState({cheemsToken})
      let cheemsTokenBalance = await cheemsToken.methods.balanceOf(this.state.account).call()
      this.setState({cheemsTokenBalance: cheemsTokenBalance.toString()})
    } else {
      window.alert('CheemsToken Contract not deployed to detected network.')
    }

    //TokenFarm init
    const tokenFarmData = TokenFarm.networks[networkId]
    if(tokenFarmData) {
      const tokenFarm = new web3.eth.Contract(TokenFarm.abi, tokenFarmData.address)
      this.setState({tokenFarm})
      let stakingBalance = await tokenFarm.methods.stakingBalance(this.state.account).call()
      this.setState({stakingBalance: stakingBalance.toString()})
    } else {
      window.alert('TokenFarm Contract not deployed to detected network.')
    }
    
    this.setState({loading: false})
  }

  async loadWeb3() {
    if(window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    } else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    } else {
      window.alert('Non-ethereum browser detected, please install metamask')
    }
  }

  stakeToken = (amount) => {
    this.setState({loading: false})
    this.state.daiToken.methods.approve(this.state.tokenFarm._address, amount).send({from: this.state.account}).on('transactionHash', (hash) => {
      this.state.tokenFarm.methods.stakeToken(amount).send({from: this.state.account}).on('transactionHash', (hash) => {
        this.setState({loading: false})
      })
    })
  }

  unstakeToken = (amount) => {
    this.setState({ loading: true })
    this.state.tokenFarm.methods.unstakeToken().send({ from: this.state.account }).on('transactionHash', (hash) => {
      this.setState({ loading: false })
    })
  }

  constructor(props) {
    super(props)
    this.state = {
      account: '0x0',
      daiToken: {},
      dappToken: {},
      tokenFarm: {},
      daiTokenBalance: '0',
      dappTokenBalance: '0',
      stakingBalance: '0',
      loading: true
    }
  }

  render() {

    let content
    if(this.state.loading) {
      content = <p id="loader" className="text-center">Loading...</p>
    } else {
      content = <Main 
        daiTokenBalance={this.state.daiTokenBalance}
        cheemsTokenBalance={this.state.cheemsTokenBalance}
        stakingBalance={this.state.stakingBalance}
        account={this.state.account}
        stakeToken={this.stakeToken}
        unstakeToken={this.unstakeToken}
      />
    }

    return (
      <div>
        <Navbar account={this.state.account} />
        <div className="container-fluid mt-5" account={this.state.account}>
          <div className="row">
            <main role="main" className="col-lg-12 ml-auto mr-auto" style={{ maxWidth: '600px' }}>
              <div className="content mr-auto ml-auto">
                <a
                  href="http://www.dappuniversity.com/bootcamp"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                </a>

                {content}

              </div>
            </main>
          </div>
        </div>
      </div>
    );
  }
}

export default App;
